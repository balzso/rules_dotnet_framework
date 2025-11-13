"""Rule for building VSTO (Visual Studio Tools for Office) add-ins"""

load("@io_bazel_rules_dotnet//dotnet/private:context.bzl", "dotnet_context")
load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
    "DotnetResourceList",
)
load("@io_bazel_rules_dotnet//dotnet/platform:list.bzl", "DOTNET_NET_FRAMEWORKS")
load("@io_bazel_rules_dotnet//dotnet/private:rules/versions.bzl", "parse_version")
load("@io_bazel_rules_dotnet//dotnet/private/vsto:office_pias.bzl", "get_office_pia_deps", "validate_office_version")
load("@io_bazel_rules_dotnet//dotnet/private/vsto:vsto_runtime.bzl", "VSTO_EXCEL_DEPS", "VSTO_WORD_DEPS", "VSTO_OUTLOOK_DEPS", "VSTO_POWERPOINT_DEPS")
load("@io_bazel_rules_dotnet//dotnet/private/actions:manifest.bzl", "emit_application_manifest")
load("@io_bazel_rules_dotnet//dotnet/private/actions:deployment_manifest.bzl", "emit_deployment_manifest")
load("@io_bazel_rules_dotnet//dotnet/private/actions:sign.bzl", "emit_sign_manifest")

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

    # Validate inputs
    if not name.endswith(".dll"):
        fail("name must end with .dll for VSTO add-ins")

    # Validate Office version
    validate_office_version(ctx.attr.office_version)

    # Handle case of empty toolchain on linux and darwin
    if dotnet.assembly == None:
        library = dotnet.new_library(dotnet = dotnet)
        return [library]

    # Get Office PIA dependencies
    pia_deps = get_office_pia_deps(ctx.attr.office_app)

    # Get VSTO runtime dependencies
    vsto_deps = _get_vsto_deps(ctx.attr.office_app)

    # Combine user deps with automatic VSTO/PIA deps
    # Note: We need to convert label strings to actual targets
    # For now, we'll just use the user-provided deps
    # TODO: Add automatic VSTO/PIA dependency injection when WORKSPACE is configured
    all_deps = ctx.attr.deps  # + pia_deps + vsto_deps

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
        # Note: These functions are placeholders - they need proper context integration
        # app_manifest = emit_application_manifest(
        #     dotnet,
        #     name = name.replace(".dll", ""),
        #     assembly = library.result,
        #     deps = all_deps,
        # )
        # output_files.append(app_manifest)

        # Generate deployment manifest (.vsto)
        # vsto_manifest = emit_deployment_manifest(
        #     dotnet,
        #     name = name.replace(".dll", ""),
        #     assembly = library.result,
        #     application_manifest = app_manifest,
        #     install_url = ctx.attr.install_url,
        # )
        # output_files.append(vsto_manifest)

        # Sign manifests if certificate is provided
        # if ctx.attr.signing_cert:
        #     signed_app_manifest = emit_sign_manifest(
        #         dotnet,
        #         manifest = app_manifest,
        #         cert_file = ctx.file.signing_cert,
        #         cert_password = ctx.attr.cert_password,
        #     )
        #     signed_vsto_manifest = emit_sign_manifest(
        #         dotnet,
        #         manifest = vsto_manifest,
        #         cert_file = ctx.file.signing_cert,
        #         cert_password = ctx.attr.cert_password,
        #     )
        #     output_files.extend([signed_app_manifest, signed_vsto_manifest])
        pass

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
        "dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:net_context_data")),
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
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_type_net"],
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
