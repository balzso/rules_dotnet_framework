"""Rules for embedding arbitrary binary/text files as .NET resources.

net_resource compiles arbitrary files (XML, images, binary data, etc.) into embedded resources
that can be included in .NET assemblies. Unlike net_resx which compiles .resx files to .resources,
net_resource handles pre-compiled .resources files or arbitrary binary/text files directly.
"""

load(
    "@rules_dotnet_framework//dotnet/private:context.bzl",
    "dotnet_context",
)
load(
    "@rules_dotnet_framework//dotnet/private:providers.bzl",
    "DotnetResourceList",
)
load("@rules_dotnet_framework//dotnet/private:paths.bzl", "paths")

def _resource_impl(ctx):
    """Implements net_resource rule for embedding arbitrary files as resources."""
    dotnet = dotnet_context(ctx)
    name = ctx.label.name

    # Handle case of empty toolchain on linux and darwin
    if dotnet.mcs == None:
        result = dotnet.declare_file(dotnet, path = "empty.resources")
        dotnet.actions.write(output = result, content = ".net not supported on this platform")
        empty = dotnet.new_resource(dotnet = dotnet, name = name, result = result)
        return [empty, DotnetResourceList(result = [empty])]

    # Get the source file
    src_file = ctx.file.src

    # Determine the identifier - use provided identifier or derive from filename
    identifier = ctx.attr.identifier if ctx.attr.identifier else src_file.basename

    # For C# compiler's /resource: flag, we can use any file directly
    # No need to convert to .resources format - the compiler accepts any binary/text file
    resource = dotnet.new_resource(
        dotnet = dotnet,
        name = name,
        result = src_file,
        identifier = identifier,
    )

    return [
        resource,
        DotnetResourceList(result = [resource]),
        DefaultInfo(
            files = depset([src_file]),
        ),
    ]

def _resource_multi_impl(ctx):
    """Implements net_resource_multi rule for embedding multiple files as resources."""
    dotnet = dotnet_context(ctx)
    name = ctx.label.name

    if ctx.attr.identifierBase != "" and ctx.attr.fixedIdentifierBase != "":
        fail("Both identifierBase and fixedIdentifierBase cannot be specified")

    result = []
    for d in ctx.attr.srcs:
        for k in d.files.to_list():
            base = paths.dirname(ctx.build_file_path)

            # Compute identifier based on path or fixed base
            if ctx.attr.identifierBase != "":
                # Replace base path with identifierBase and use dots instead of slashes
                identifier = k.path.replace(base, ctx.attr.identifierBase, 1)
                identifier = identifier.replace("/", ".")
                identifier = identifier.replace("\\", ".")  # Handle Windows paths
            else:
                # Use fixed base + basename
                identifier = ctx.attr.fixedIdentifierBase + "." + paths.basename(k.path)

            resource = dotnet.new_resource(
                dotnet = dotnet,
                name = identifier,
                result = k,
                identifier = identifier,
            )
            result.append(resource)

    return [
        DotnetResourceList(result = result),
        DefaultInfo(
            files = depset([d.result for d in result]),
        ),
    ]

# .NET Framework version
net_resource = rule(
    _resource_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Source file to embed as a resource (can be any file type: .xml, .xlsx, .png, etc.)",
        ),
        "identifier": attr.string(
            doc = "Resource identifier string (e.g., 'MyNamespace.MyResource.xml'). If not specified, uses the filename.",
        ),
        "dotnet_context_data": attr.label(
            default = Label("@rules_dotnet_framework//:net_context_data"),
        ),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_net"],
    executable = False,
    doc = """Embeds an arbitrary file as a .NET embedded resource.

    This rule allows embedding any file (XML, images, templates, etc.) directly into a .NET assembly
    as an embedded resource. The file can later be accessed via Assembly.GetManifestResourceStream().

    Example:
        net_resource(
            name = "Ribbon_xml",
            src = "Ribbon.xml",
            identifier = "MyAddIn.Ribbon.xml",
        )

        net_library(
            name = "MyLib.dll",
            srcs = ["MyClass.cs"],
            resources = [":Ribbon_xml"],
        )
    """,
)

# Mono version (for compatibility, though not actively used in this fork)
dotnet_resource = rule(
    _resource_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "identifier": attr.string(),
        "dotnet_context_data": attr.label(default = Label("@rules_dotnet_framework//:net_context_data")),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_mono"],
    executable = False,
)

# .NET Core version (for compatibility, though not actively used in this fork)
core_resource = rule(
    _resource_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "identifier": attr.string(),
        "dotnet_context_data": attr.label(default = Label("@rules_dotnet_framework//:core_context_data")),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_core"],
    executable = False,
)

# .NET Framework multi-resource version
net_resource_multi = rule(
    _resource_multi_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "List of files to embed as resources",
        ),
        "identifierBase": attr.string(
            doc = "Base identifier - file paths will be converted to dotted notation relative to this base",
        ),
        "fixedIdentifierBase": attr.string(
            doc = "Fixed base identifier - each file will use this base + filename",
        ),
        "dotnet_context_data": attr.label(
            default = Label("@rules_dotnet_framework//:net_context_data"),
        ),
    },
    toolchains = ["@rules_dotnet_framework//dotnet:toolchain_type_net"],
    executable = False,
    doc = """Embeds multiple files as .NET embedded resources.

    Similar to net_resource but handles multiple files at once. The identifier for each resource
    is computed based on either identifierBase (path-based) or fixedIdentifierBase (fixed prefix).

    Example:
        net_resource_multi(
            name = "templates",
            srcs = glob(["Resources/*.xlsx"]),
            identifierBase = "MyAddIn",
        )

        # Creates resources like:
        # MyAddIn.Resources.Template1.xlsx
        # MyAddIn.Resources.Template2.xlsx
    """,
)
