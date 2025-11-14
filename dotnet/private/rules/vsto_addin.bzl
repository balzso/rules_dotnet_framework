"""Rule for building VSTO (Visual Studio Tools for Office) add-ins"""

load("@rules_dotnet_framework//dotnet/private:context.bzl", "dotnet_context")
load(
    "@rules_dotnet_framework//dotnet/private:providers.bzl",
    "DotnetLibrary",
    "DotnetResourceList",
)
load("@rules_dotnet_framework//dotnet/platform:list.bzl", "DOTNET_NET_FRAMEWORKS")
load("@rules_dotnet_framework//dotnet/private/rules:versions.bzl", "parse_version")
load("@rules_dotnet_framework//dotnet/private/vsto:office_pias.bzl", "get_office_pia_deps", "validate_office_version")
load("@rules_dotnet_framework//dotnet/private/vsto:vsto_runtime.bzl", "VSTO_EXCEL_DEPS", "VSTO_WORD_DEPS", "VSTO_OUTLOOK_DEPS", "VSTO_POWERPOINT_DEPS")
load("@rules_dotnet_framework//dotnet/private/actions:manifest.bzl", "emit_application_manifest")
load("@rules_dotnet_framework//dotnet/private/actions:deployment_manifest.bzl", "emit_deployment_manifest")
load("@rules_dotnet_framework//dotnet/private/actions:sign.bzl", "emit_sign_manifest")

def _get_vsto_deps(office_app):
    """Returns VSTO runtime dependencies for the specified Office application"""
    if office_app == "Excel":
        return VSTO_EXCEL_DEPS
    elif office_app == "Word":
        return VSTO_WORD_DEPS
    elif office_app == "Outlook":
        return VSTO_OUTLOOK_DEPS
    elif office_app == "PowerPoint":
        return VSTO_POWERPOINT_DEPS
    else:
        fail("Unknown Office application: {}".format(office_app))

def _vsto_addin_impl(ctx):
    """Implementation of net_vsto_addin rule"""
    dotnet = dotnet_context(ctx)
    name = ctx.label.name

    # Override mage_wrapper in dotnet context from rule attribute
    if ctx.executable.mage_wrapper:
        # Create a new struct with mage_wrapper added, preserving all fields including private ones
        dotnet_dict = {k: getattr(dotnet, k) for k in dir(dotnet)}
        dotnet_dict["mage_wrapper"] = ctx.executable.mage_wrapper
        dotnet = struct(**dotnet_dict)

    # Validate inputs
    if not name.endswith(".dll"):
        fail("name must end with .dll for VSTO add-ins")

    # Validate Office version
    validate_office_version(ctx.attr.office_version)

    # Handle case of empty toolchain on linux and darwin
    if dotnet.assembly == None:
        library = dotnet.new_library(dotnet = dotnet)
        return [library]

    # Get Office PIA dependencies from private attributes
    pia_deps = []
    if ctx.attr.office_app == "Excel":
        pia_deps = ctx.attr._pia_excel_deps
    elif ctx.attr.office_app == "Word":
        pia_deps = ctx.attr._pia_word_deps
    elif ctx.attr.office_app == "Outlook":
        pia_deps = ctx.attr._pia_outlook_deps
    elif ctx.attr.office_app == "PowerPoint":
        pia_deps = ctx.attr._pia_powerpoint_deps

    # Get VSTO runtime dependencies from private attributes
    vsto_deps = []
    if ctx.attr.office_app == "Excel":
        vsto_deps = ctx.attr._vsto_excel_deps
    elif ctx.attr.office_app == "Word":
        vsto_deps = ctx.attr._vsto_word_deps
    elif ctx.attr.office_app == "Outlook":
        vsto_deps = ctx.attr._vsto_outlook_deps
    elif ctx.attr.office_app == "PowerPoint":
        vsto_deps = ctx.attr._vsto_powerpoint_deps

    # Combine user deps with automatic VSTO/PIA deps + stdlib
    all_deps = ctx.attr.deps + pia_deps + vsto_deps + ctx.attr._stdlib

    # Build the add-in assembly (DLL)
    library = dotnet.assembly(
        dotnet,
        name = name,
        srcs = ctx.attr.srcs,
        deps = all_deps,
        resources = ctx.attr.resources,
        out = ctx.attr.out if ctx.attr.out else name,
        defines = ctx.attr.defines,
        unsafe = ctx.attr.unsafe,
        data = ctx.attr.data,
        keyfile = ctx.attr.keyfile,
        executable = False,  # VSTO add-ins are DLLs, not EXEs
        target_framework = ctx.attr.target_framework,
        nowarn = ctx.attr.nowarn,
        langversion = ctx.attr.langversion,
        version = (0, 0, 0, 0, "") if ctx.attr.version == "" else parse_version(ctx.attr.version),
    )

    output_files = [library.result]

    # Generate application manifest if requested
    if ctx.attr.generate_manifests:
        # Generate application manifest (.dll.manifest)
        app_manifest = emit_application_manifest(
            dotnet,
            name = name.replace(".dll", ""),
            assembly = library.result,
            deps = all_deps,
        )
        output_files.append(app_manifest)

        # Generate deployment manifest (.vsto)
        vsto_manifest = emit_deployment_manifest(
            dotnet,
            name = name.replace(".dll", ""),
            assembly = library.result,
            application_manifest = app_manifest,
            install_url = ctx.attr.install_url,
        )
        output_files.append(vsto_manifest)

        # Sign manifests if certificate is provided
        if ctx.file.signing_cert:
            signed_app_manifest = emit_sign_manifest(
                dotnet,
                manifest = app_manifest,
                cert_file = ctx.file.signing_cert,
                cert_password = ctx.attr.cert_password,
            )
            signed_vsto_manifest = emit_sign_manifest(
                dotnet,
                manifest = vsto_manifest,
                cert_file = ctx.file.signing_cert,
                cert_password = ctx.attr.cert_password,
            )
            output_files.extend([signed_app_manifest, signed_vsto_manifest])

    return [
        library,
        DefaultInfo(
            files = depset(output_files),
            runfiles = ctx.runfiles(files = [], transitive_files = depset(transitive = [t.runfiles for t in library.transitive])),
        ),
    ]

net_vsto_addin = rule(
    _vsto_addin_impl,
    attrs = {
        # Standard .NET library attributes
        "deps": attr.label_list(providers = [DotnetLibrary]),
        "version": attr.string(),
        "resources": attr.label_list(providers = [DotnetResourceList]),
        "srcs": attr.label_list(allow_files = [".cs"]),
        "out": attr.string(),
        "defines": attr.string_list(),
        "unsafe": attr.bool(default = False),
        "data": attr.label_list(allow_files = True),
        "keyfile": attr.label(allow_files = True),
        "dotnet_context_data": attr.label(default = Label("@rules_dotnet_framework//:net_context_data")),
        "target_framework": attr.string(
            values = DOTNET_NET_FRAMEWORKS.keys() + [""],
            default = "net472",  # Default to .NET Framework 4.7.2 for VSTO
        ),
        "nowarn": attr.string_list(),
        "langversion": attr.string(default = "latest"),

        # VSTO-specific attributes
        "office_app": attr.string(
            mandatory = True,
            doc = "The Office application for this add-in (Excel, Word, Outlook, PowerPoint)",
        ),
        "office_version": attr.string(
            default = "2016",
            doc = "Minimum Office version (2013, 2016, 2019, 2021, 365)",
        ),
        "generate_manifests": attr.bool(
            default = True,
            doc = "Generate ClickOnce application and deployment manifests",
        ),
        "install_url": attr.string(
            doc = "Optional installation URL for network deployment",
        ),
        "signing_cert": attr.label(
            allow_single_file = [".pfx"],
            doc = "Optional PFX certificate file for Authenticode signing",
        ),
        "cert_password": attr.string(
            doc = "Optional certificate password",
        ),
        "mage_wrapper": attr.label(
            executable = True,
            cfg = "host",
            doc = "Optional mage_wrapper tool (auto-selected based on target_framework if not specified)",
        ),

        # Private attributes for automatic dependency injection
        # Office PIA dependencies
        "_pia_excel_deps": attr.label_list(
            default = [Label("@microsoft.office.interop.excel//:lib")],
            providers = [DotnetLibrary],
        ),
        "_pia_word_deps": attr.label_list(
            default = [Label("@microsoft.office.interop.word//:lib")],
            providers = [DotnetLibrary],
        ),
        "_pia_outlook_deps": attr.label_list(
            default = [Label("@microsoft.office.interop.outlook//:lib")],
            providers = [DotnetLibrary],
        ),
        "_pia_powerpoint_deps": attr.label_list(
            default = [Label("@microsoft.office.interop.powerpoint//:lib")],
            providers = [DotnetLibrary],
        ),

        # VSTO runtime dependencies
        "_vsto_excel_deps": attr.label_list(
            default = [
                Label("@vsto_runtime//:Microsoft.Office.Tools.Common"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.Excel"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.Excel.v4.0.Utilities"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework"),
                Label("@vsto_runtime//:Microsoft.Office.Tools"),
                Label("@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime"),
            ],
            providers = [DotnetLibrary],
        ),
        "_vsto_word_deps": attr.label_list(
            default = [
                Label("@vsto_runtime//:Microsoft.Office.Tools.Common"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.Word"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework"),
                Label("@vsto_runtime//:Microsoft.Office.Tools"),
                Label("@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime"),
            ],
            providers = [DotnetLibrary],
        ),
        "_vsto_outlook_deps": attr.label_list(
            default = [
                Label("@vsto_runtime//:Microsoft.Office.Tools.Common"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.Outlook"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework"),
                Label("@vsto_runtime//:Microsoft.Office.Tools"),
                Label("@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime"),
            ],
            providers = [DotnetLibrary],
        ),
        "_vsto_powerpoint_deps": attr.label_list(
            default = [
                Label("@vsto_runtime//:Microsoft.Office.Tools.Common"),
                Label("@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework"),
                Label("@vsto_runtime//:Microsoft.Office.Tools"),
                Label("@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime"),
            ],
            providers = [DotnetLibrary],
        ),
        # Standard library dependencies (automatically injected)
        "_stdlib": attr.label_list(
            default = [
                Label("@rules_dotnet_framework//dotnet/stdlib.net:mscorlib.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.core.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.drawing.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.windows.forms.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.xml.dll"),
                Label("@rules_dotnet_framework//dotnet/stdlib.net:system.data.dll"),
            ],
            providers = [DotnetLibrary],
        ),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_net"],
    executable = False,
    doc = """
Builds a VSTO (Visual Studio Tools for Office) add-in.

Example:
    net_vsto_addin(
        name = "MyExcelAddIn.dll",
        srcs = ["ThisAddIn.cs", "Ribbon1.cs"],
        office_app = "Excel",
        office_version = "2016",
        keyfile = "MyAddIn.snk",
        signing_cert = "cert.pfx",
    )
""",
)
