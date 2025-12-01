"""VSTO Utilities repository rule for locating VSTO runtime utility assemblies"""

def _detect_vsto_utilities(ctx):
    """
    Detects VSTO Utilities DLLs in Visual Studio installation.

    These assemblies are required for VSTO add-in installers but are not
    included in the add-in's bin output (they have Private=False in .csproj).

    Location: Visual Studio installation / Common7/IDE/ReferenceAssemblies/v4.0/

    Files:
    - Microsoft.Office.Tools.Common.v4.0.Utilities.dll
    - Microsoft.Office.Tools.Excel.v4.0.Utilities.dll
    - Microsoft.Office.Tools.Word.v4.0.Utilities.dll
    - Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll
    """

    # Try explicit path first
    if ctx.attr.utilities_path:
        base_path = ctx.path(ctx.attr.utilities_path)
        if base_path.exists:
            return base_path
        else:
            fail("Specified VSTO utilities_path does not exist: {}".format(ctx.attr.utilities_path))

    # Auto-detect Visual Studio installation
    vs_editions = ["Enterprise", "Professional", "Community", "BuildTools"]
    vs_years = ["2022", "2019", "2017"]

    # Check common Visual Studio paths
    program_files_paths = [
        "C:/Program Files/Microsoft Visual Studio",
        "C:/Program Files (x86)/Microsoft Visual Studio",
    ]

    for program_files in program_files_paths:
        for year in vs_years:
            for edition in vs_editions:
                utilities_path = "{}/{}/{}/Common7/IDE/ReferenceAssemblies/v4.0".format(
                    program_files,
                    year,
                    edition,
                )

                defpath = ctx.path(utilities_path)
                if defpath.exists:
                    # Verify that key assemblies exist
                    common_dll = ctx.path(utilities_path + "/Microsoft.Office.Tools.Common.v4.0.Utilities.dll")
                    if common_dll.exists:
                        return defpath

    # Not found - provide helpful error
    fail("""
VSTO Utilities assemblies not found!

These assemblies are required for VSTO installer builds. They are part of the
Visual Studio Tools for Office (VSTO) development tools.

To fix this:

Option 1: Install Visual Studio with Office Developer Tools
  - Install Visual Studio 2022, 2019, or 2017
  - Include "Office/SharePoint development" workload

Option 2: Specify explicit path in WORKSPACE:
  vsto_utilities_register(
      utilities_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/ReferenceAssemblies/v4.0"
  )

Required files:
  - Microsoft.Office.Tools.Common.v4.0.Utilities.dll
  - Microsoft.Office.Tools.Excel.v4.0.Utilities.dll
  - Microsoft.Office.Tools.Word.v4.0.Utilities.dll
  - Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll
""")

def _vsto_utilities_register_impl(ctx):
    """Implementation of vsto_utilities_register repository rule"""

    # Detect VSTO Utilities path
    utilities_path = _detect_vsto_utilities(ctx)

    # Create BUILD file
    ctx.file("BUILD.bazel", """
# VSTO Utilities Assemblies

filegroup(
    name = "dlls",
    srcs = [
        "Microsoft.Office.Tools.Common.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Excel.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Word.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll",
    ],
    visibility = ["//visibility:public"],
)

# Individual exports for selective use
exports_files([
    "Microsoft.Office.Tools.Common.v4.0.Utilities.dll",
    "Microsoft.Office.Tools.Excel.v4.0.Utilities.dll",
    "Microsoft.Office.Tools.Word.v4.0.Utilities.dll",
    "Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll",
])
""")

    # Symlink the DLL files
    utilities = [
        "Microsoft.Office.Tools.Common.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Excel.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Word.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll",
    ]

    for dll in utilities:
        dll_path = ctx.path(str(utilities_path) + "/" + dll)
        if dll_path.exists:
            ctx.symlink(dll_path, dll)

    # Store the path for use as bindpath
    ctx.file("PATH", str(utilities_path))

vsto_utilities_register = repository_rule(
    _vsto_utilities_register_impl,
    attrs = {
        "utilities_path": attr.string(
            doc = "Explicit path to VSTO Utilities directory. If not specified, auto-detection will be attempted.",
        ),
    },
    doc = """
Registers VSTO Utilities assemblies for installer builds.

These assemblies are required by WiX installer builds for VSTO add-ins, but are
not included in the add-in's build output (Private=False in .csproj).

Example usage in WORKSPACE:

    load("@rules_dotnet_framework//dotnet/toolchain:toolchains.bzl", "vsto_utilities_register")

    vsto_utilities_register(name = "vsto_utilities")

    # Or with explicit path:
    vsto_utilities_register(
        name = "vsto_utilities",
        utilities_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/ReferenceAssemblies/v4.0",
    )
""",
)
