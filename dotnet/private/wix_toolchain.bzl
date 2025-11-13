"""WiX Toolset v5 toolchain for building Windows Installer packages"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def _get_dotnet_wix(context_data):
    """Gets the wix.exe tool from the toolchain"""
    return _get_wix_tool(context_data, "wix.exe")

def _get_wix_tool(context_data, name):
    """
    Locates a WiX tool by name.

    WiX v5 uses a single wix.exe tool (unlike WiX v3 with candle.exe/light.exe).
    """
    # Check if WiX tools are provided in the toolchain
    if not hasattr(context_data, "_wix_tools") or context_data._wix_tools == None:
        fail("WiX tools not configured in toolchain. Ensure wix_register_sdk() is called in WORKSPACE.")

    for f in context_data._wix_tools.files.to_list():
        basename = paths.basename(f.path)
        if basename.lower() == name.lower():
            return f

    fail("Could not find {} in WiX SDK".format(name))

def _detect_wix_sdk(ctx):
    """
    Detects WiX Toolset v5 installation.

    Searches in common locations:
    1. .NET global tools: ~/.dotnet/tools/wix.exe (Windows: %USERPROFILE%\.dotnet\tools)
    2. NuGet cache: ~/.nuget/packages/wix/[version]/tools/net6.0/any/wix.exe
    3. Explicit path provided via wix_register_sdk(wix_path = "...")

    Returns the path to wix.exe if found, or None.
    """
    # Common WiX v5 installation paths
    wix_paths = []

    # 1. .NET global tools
    if ctx.os.name.startswith("windows"):
        userprofile = ctx.os.environ.get("USERPROFILE", "")
        if userprofile:
            wix_paths.append(userprofile + "/.dotnet/tools/wix.exe")
            wix_paths.append(userprofile + "\\.dotnet\\tools\\wix.exe")
    else:
        # Unix-like systems (though WiX is Windows-only, support for cross-compilation)
        home = ctx.os.environ.get("HOME", "")
        if home:
            wix_paths.append(home + "/.dotnet/tools/wix")

    # 2. NuGet global cache
    # ~/.nuget/packages/wix/5.0.2/tools/net6.0/any/wix.exe
    nuget_cache = ctx.os.environ.get("NUGET_PACKAGES", "")
    if not nuget_cache:
        if ctx.os.name.startswith("windows"):
            userprofile = ctx.os.environ.get("USERPROFILE", "")
            if userprofile:
                nuget_cache = userprofile + "\\.nuget\\packages"
        else:
            home = ctx.os.environ.get("HOME", "")
            if home:
                nuget_cache = home + "/.nuget/packages"

    if nuget_cache:
        # Try common versions (5.0.2, 5.0.1, 5.0.0, 6.0.0)
        for version in ["6.0.0", "5.0.2", "5.0.1", "5.0.0"]:
            wix_exe_path = "{}/wix/{}/tools/net6.0/any/wix.exe".format(nuget_cache, version)
            wix_paths.append(wix_exe_path)
            # Windows path variant
            wix_exe_path_win = "{}\\wix\\{}\\tools\\net6.0\\any\\wix.exe".format(nuget_cache, version)
            wix_paths.append(wix_exe_path_win)

    # 3. Search for wix.exe
    for wix_path in wix_paths:
        defpath = ctx.path(wix_path)
        if defpath.exists:
            return defpath

    # WiX not found - this is not a hard failure since it can be provided explicitly
    return None

def _wix_toolchain_impl(ctx):
    """Implementation of wix_toolchain rule"""

    # Get WiX extensions if specified
    extensions = {}
    for ext_name, ext_label in ctx.attr.extensions.items():
        extensions[ext_name] = ext_label

    return [platform_common.ToolchainInfo(
        name = ctx.label.name,
        wiximpl = ctx.attr.wiximpl,
        get_dotnet_wix = _get_dotnet_wix,
        wix_extensions = extensions,
    )]

_wix_toolchain = rule(
    _wix_toolchain_impl,
    attrs = {
        "wiximpl": attr.string(mandatory = True, doc = "WiX implementation version (e.g., 'wix5')"),
        "extensions": attr.label_keyed_string_dict(
            doc = "WiX extension packages (name -> label mapping)",
        ),
    },
)

def wix_toolchain(name, extensions = {}, **kwargs):
    """
    Defines a WiX toolchain.

    Args:
        name: Name of the toolchain
        extensions: Dictionary of WiX extensions (name -> NuGet package label)
                   Example: {
                       "WixToolset.UI.wixext": "@wix_ui_ext//:lib",
                       "WixToolset.Util.wixext": "@wix_util_ext//:lib",
                   }
        **kwargs: Additional arguments passed to the toolchain
    """

    impl_name = name + "-impl"
    _wix_toolchain(
        name = impl_name,
        wiximpl = "wix5",
        extensions = extensions,
        **kwargs
    )

    native.toolchain(
        name = name,
        toolchain = ":" + impl_name,
        toolchain_type = "@io_bazel_rules_dotnet//dotnet:wix_toolchain_type",
    )
