"""WiX SDK repository rule for detecting and configuring WiX Toolset v5"""

def _detect_wix_exe(ctx):
    """
    Detects wix.exe location.

    Search order:
    1. Explicit path from wix_register_sdk(wix_path = "...")
    2. .NET global tools (~/.dotnet/tools/wix.exe)
    3. NuGet global cache (~/.nuget/packages/wix/[version]/tools/net6.0/any/wix.exe)
    """

    # 1. Check explicit path
    if ctx.attr.wix_path:
        defpath = ctx.path(ctx.attr.wix_path)
        if defpath.exists:
            return defpath
        else:
            fail("Specified wix_path does not exist: {}".format(ctx.attr.wix_path))

    # 2. .NET global tools
    if ctx.os.name.startswith("windows"):
        userprofile = ctx.os.environ.get("USERPROFILE", "")
        if userprofile:
            # Try with forward slashes
            wix_tool_path = userprofile + "/.dotnet/tools/wix.exe"
            defpath = ctx.path(wix_tool_path)
            if defpath.exists:
                return defpath

            # Try with backslashes
            wix_tool_path = userprofile + "\\.dotnet\\tools\\wix.exe"
            defpath = ctx.path(wix_tool_path)
            if defpath.exists:
                return defpath

    # 3. NuGet global cache
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
        # Try versions in descending order
        for version in ["6.0.2", "6.0.1", "6.0.0", "5.0.2", "5.0.1", "5.0.0"]:
            # Forward slashes
            wix_exe = "{}/wix/{}/tools/net6.0/any/wix.exe".format(nuget_cache, version)
            defpath = ctx.path(wix_exe)
            if defpath.exists:
                return defpath

            # Backslashes (Windows)
            wix_exe = "{}\\wix\\{}\\tools\\net6.0\\any\\wix.exe".format(nuget_cache, version)
            defpath = ctx.path(wix_exe)
            if defpath.exists:
                return defpath

    # Not found
    fail("""
WiX Toolset v5 not found!

To use WiX installer builds, install WiX v5:

Option 1: Install as .NET global tool (recommended):
  dotnet tool install -g wix

Option 2: Specify explicit path in WORKSPACE:
  wix_register_sdk(wix_path = "C:/path/to/wix.exe")

Option 3: Add WiX as NuGet package to your project
  (wix.exe will be in ~/.nuget/packages/wix/[version]/tools/net6.0/any/)

For more information, see: https://wixtoolset.org/docs/intro/
""")

def _wix_register_sdk_impl(ctx):
    """Implementation of wix_register_sdk repository rule"""

    # Detect wix.exe
    wix_exe = _detect_wix_exe(ctx)

    # Create a simple BUILD file that exposes wix.exe
    ctx.file("BUILD.bazel", """
# WiX Toolset SDK

exports_files(["wix.exe"])

filegroup(
    name = "wix_tools",
    srcs = ["wix.exe"],
    visibility = ["//visibility:public"],
)
""")

    # Symlink wix.exe into the repository
    ctx.symlink(wix_exe, "wix.exe")

    # Create a marker file with version info
    ctx.file("VERSION", "WiX Toolset v5 (detected at: {})".format(wix_exe))

wix_register_sdk = repository_rule(
    _wix_register_sdk_impl,
    attrs = {
        "wix_path": attr.string(
            doc = "Explicit path to wix.exe. If not specified, auto-detection will be attempted.",
        ),
    },
    environ = ["USERPROFILE", "HOME", "NUGET_PACKAGES"],
    doc = """
Registers the WiX Toolset v5 SDK.

This repository rule detects the wix.exe tool and makes it available to Bazel builds.

Example usage in WORKSPACE:

    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "wix_register_sdk")

    wix_register_sdk(name = "wix_sdk")

    # Or with explicit path:
    wix_register_sdk(
        name = "wix_sdk",
        wix_path = "C:/Users/MyUser/.dotnet/tools/wix.exe",
    )
""",
)
