"""WiX package rule for building Windows Installer (.msi) packages"""

load(
    "@rules_dotnet_framework//dotnet/private:context.bzl",
    "dotnet_context",
)
load(
    "@rules_dotnet_framework//dotnet/private:providers.bzl",
    "DotnetLibrary",
)
load(
    "@rules_dotnet_framework//dotnet/private/actions:wix_stage.bzl",
    "stage_vsto_files_for_wix_windows",
)
load(
    "@rules_dotnet_framework//dotnet/private/actions:wix_build.bzl",
    "emit_wix_package_with_wrapper",
)
load(
    "@rules_dotnet_framework//dotnet/private/actions:sign.bzl",
    "emit_sign_msi",
)

def _wix_package_impl(ctx):
    """Implementation of the wix_package rule.

    This rule builds a Windows Installer (.msi) package from WiX source files.
    It can optionally stage VSTO add-in files and sign the resulting MSI.
    """

    # Get dotnet context for toolchain access
    dotnet = dotnet_context(ctx)

    # Validate inputs
    if not ctx.attr.name.endswith(".msi"):
        fail("wix_package name must end with .msi: {}".format(ctx.attr.name))

    if len(ctx.files.srcs) == 0:
        fail("wix_package requires at least one .wxs source file")

    # Check that all srcs are .wxs files
    for src in ctx.files.srcs:
        if not src.path.endswith(".wxs"):
            fail("wix_package srcs must be .wxs files: {}".format(src.path))

    # Stage VSTO files if vsto_addin is provided
    staging_dir = None
    if ctx.attr.vsto_addin:
        # Get DotnetLibrary provider from vsto_addin target
        vsto_library = ctx.attr.vsto_addin[DotnetLibrary]

        # Stage files for WiX build
        staging_dir = stage_vsto_files_for_wix_windows(
            ctx = ctx,
            name = ctx.attr.name.replace(".msi", ""),
            vsto_library = vsto_library,
        )
    elif ctx.attr.staging_dir:
        # Use explicitly provided staging directory
        staging_dir = ctx.file.staging_dir

    # If no staging_dir, we still need one for WiX (can be empty)
    if not staging_dir:
        # Create an empty staging directory
        staging_dir = ctx.actions.declare_directory(ctx.attr.name.replace(".msi", "") + "_staging")
        ctx.actions.run_shell(
            command = "mkdir \"{}\"".format(staging_dir.path.replace("/", "\\\\")),
            outputs = [staging_dir],
            mnemonic = "WixCreateEmptyStaging",
            progress_message = "Creating empty staging directory",
        )

    # Get WiX tool and wrapper from toolchain
    # TODO: This needs proper toolchain support - for now, use attributes
    wix_tool = ctx.file._wix_tool
    wix_wrapper = ctx.executable._wix_wrapper

    if not wix_tool:
        fail("WiX tool not found. Ensure wix_register_sdk() is called in WORKSPACE.")

    if not wix_wrapper:
        fail("WiX wrapper not found. This is a build configuration error.")

    # Build WiX package
    msi_output = emit_wix_package_with_wrapper(
        ctx = ctx,
        name = ctx.attr.name.replace(".msi", ""),
        wxs_srcs = ctx.files.srcs,
        staging_dir = staging_dir,
        wix_wrapper = wix_wrapper,
        wix_tool = wix_tool,
        arch = ctx.attr.arch,
        defines = ctx.attr.defines,
        bindpaths = ctx.attr.bindpaths,
        extensions = ctx.attr.extensions,
        data_files = ctx.files.data,
    )

    # Sign MSI if certificate is provided
    final_msi = msi_output
    if ctx.file.cert_file or ctx.attr.cert_thumbprint:
        signed_msi = emit_sign_msi(
            dotnet = dotnet,
            msi = msi_output,
            cert_file = ctx.file.cert_file,
            cert_password = ctx.attr.cert_password,
            cert_thumbprint = ctx.attr.cert_thumbprint,
            timestamp_url = ctx.attr.timestamp_url,
            description = ctx.attr.sign_description,
        )
        final_msi = signed_msi

    return [
        DefaultInfo(
            files = depset([final_msi]),
            runfiles = ctx.runfiles(files = [final_msi]),
        ),
    ]

wix_package = rule(
    implementation = _wix_package_impl,
    doc = """Builds a Windows Installer (.msi) package using WiX Toolset v5.

    This rule compiles WiX source files (.wxs) into an MSI package.
    It can optionally stage VSTO add-in files and sign the resulting MSI.

    Example:
        wix_package(
            name = "MyInstaller.msi",
            srcs = ["Product.wxs", "Files.wxs"],
            vsto_addin = ":MyExcelAddIn.dll",
            arch = "x86",
            defines = {
                "ProductVersion": "1.0.0",
                "ProductCode": "*",  # Auto-generate
            },
            bindpaths = {
                "VsReferenceAssemblies": "$(VSTO_UTILITIES_PATH)",
            },
            extensions = ["WixToolset.UI.wixext"],
            cert_file = "certificate.pfx",
            cert_password = "password",
        )
    """,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".wxs"],
            mandatory = True,
            doc = "WiX source files (.wxs)",
        ),
        "vsto_addin": attr.label(
            providers = [DotnetLibrary],
            doc = "Optional VSTO add-in target to include in the installer",
        ),
        "staging_dir": attr.label(
            allow_single_file = True,
            doc = "Optional explicit staging directory (tree artifact)",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Additional data files (e.g., License.rtf, icons)",
        ),
        "arch": attr.string(
            default = "x86",
            values = ["x86", "x64", "ARM64"],
            doc = "Target architecture (x86, x64, ARM64)",
        ),
        "defines": attr.string_dict(
            default = {},
            doc = "WiX preprocessor variables (e.g., {'ProductVersion': '1.0.0'})",
        ),
        "bindpaths": attr.string_dict(
            default = {},
            doc = "WiX bindpath mappings (e.g., {'VsReferenceAssemblies': '/path'})",
        ),
        "extensions": attr.string_list(
            default = [],
            doc = "WiX extension names (e.g., ['WixToolset.UI.wixext'])",
        ),
        # Signing attributes
        "cert_file": attr.label(
            allow_single_file = [".pfx"],
            doc = "Optional PFX certificate file for signing the MSI",
        ),
        "cert_password": attr.string(
            doc = "Optional certificate password",
        ),
        "cert_thumbprint": attr.string(
            doc = "Optional certificate thumbprint (for certificate store)",
        ),
        "timestamp_url": attr.string(
            default = "http://timestamp.digicert.com",
            doc = "Timestamp server URL for signing",
        ),
        "sign_description": attr.string(
            doc = "Optional description for the Authenticode signature",
        ),
        # Toolchain attributes (private)
        "_wix_tool": attr.label(
            default = "@wix_sdk//:wix.exe",
            allow_single_file = True,
            doc = "WiX tool (wix.exe) from SDK",
        ),
        "_wix_wrapper": attr.label(
            default = "@rules_dotnet_framework//dotnet/tools/wix_wrapper:wix_wrapper_net472.exe",
            executable = True,
            cfg = "exec",
            doc = "WiX wrapper executable",
        ),
        "dotnet_context_data": attr.label(
            default = Label("@rules_dotnet_framework//:net_context_data"),
            doc = ".NET context data for toolchain configuration",
        ),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_net"],
)
