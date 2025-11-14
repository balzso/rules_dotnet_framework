"""VSTO Runtime detection and import infrastructure"""

# NOTE: Import directly from source to avoid circular dependency with defs.bzl
load("@rules_dotnet_framework//dotnet/private/rules:import.bzl", "net_import_library")
load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def _find_vsto_runtime_path():
    """
    Finds the VSTO runtime assemblies in the Visual Studio installation.

    Typical paths:
    - C:/Program Files (x86)/Microsoft Visual Studio/Shared/Visual Studio Tools for Office/PIA/
    - C:/Program Files/Microsoft Visual Studio/Shared/Visual Studio Tools for Office/PIA/

    Returns the base path or None if not found.
    """
    # This will be implemented in sdk_net.bzl as part of SDK detection
    # For now, we'll document the expected paths
    pass

def declare_vsto_runtime_imports(vsto_path = None):
    """
    Declares net_import_library rules for VSTO runtime assemblies.

    Args:
        vsto_path: Optional explicit path to VSTO runtime assemblies.
                   If not provided, will attempt auto-detection.

    Creates the following import targets:
        @vsto_runtime//:Microsoft.Office.Tools.Common
        @vsto_runtime//:Microsoft.Office.Tools.Excel
        @vsto_runtime//:Microsoft.Office.Tools.Word
        @vsto_runtime//:Microsoft.Office.Tools.Outlook
        @vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework
        @vsto_runtime//:Microsoft.Office.Tools
        @vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime
    """

    # VSTO Runtime assemblies that need to be imported
    vsto_assemblies = {
        "Microsoft.Office.Tools.Common": "Microsoft.Office.Tools.Common.dll",
        "Microsoft.Office.Tools.Excel": "Microsoft.Office.Tools.Excel.dll",
        "Microsoft.Office.Tools.Excel.v4.0.Utilities": "Microsoft.Office.Tools.Excel.v4.0.Utilities.dll",
        "Microsoft.Office.Tools.Word": "Microsoft.Office.Tools.Word.dll",
        "Microsoft.Office.Tools.Outlook": "Microsoft.Office.Tools.Outlook.dll",
        "Microsoft.Office.Tools.v4.0.Framework": "Microsoft.Office.Tools.v4.0.Framework.dll",
        "Microsoft.Office.Tools": "Microsoft.Office.Tools.dll",
        "Microsoft.VisualStudio.Tools.Applications.Runtime": "Microsoft.VisualStudio.Tools.Applications.Runtime.dll",
        "Microsoft.VisualStudio.Tools.Applications.ServerDocument": "Microsoft.VisualStudio.Tools.Applications.ServerDocument.dll",
    }

    # Note: The actual implementation will use repository_ctx to detect paths
    # and create import rules. For now, this serves as documentation.

    return vsto_assemblies

# Standard VSTO runtime dependency groups for different Office applications
VSTO_EXCEL_DEPS = [
    "@vsto_runtime//:Microsoft.Office.Tools.Common",
    "@vsto_runtime//:Microsoft.Office.Tools.Excel",
    "@vsto_runtime//:Microsoft.Office.Tools.Excel.v4.0.Utilities",
    "@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework",
    "@vsto_runtime//:Microsoft.Office.Tools",
    "@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime",
]

VSTO_WORD_DEPS = [
    "@vsto_runtime//:Microsoft.Office.Tools.Common",
    "@vsto_runtime//:Microsoft.Office.Tools.Word",
    "@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework",
    "@vsto_runtime//:Microsoft.Office.Tools",
    "@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime",
]

VSTO_OUTLOOK_DEPS = [
    "@vsto_runtime//:Microsoft.Office.Tools.Common",
    "@vsto_runtime//:Microsoft.Office.Tools.Outlook",
    "@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework",
    "@vsto_runtime//:Microsoft.Office.Tools",
    "@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime",
]

VSTO_POWERPOINT_DEPS = [
    "@vsto_runtime//:Microsoft.Office.Tools.Common",
    "@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework",
    "@vsto_runtime//:Microsoft.Office.Tools",
    "@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime",
]

def _detect_vsto_runtime_path(ctx):
    """
    Detects VSTO runtime DLLs in Visual Studio installation.

    Location: Visual Studio installation / Common7/IDE/ReferenceAssemblies/v4.0/
    or: C:/Program Files/Microsoft Visual Studio/2022/[Edition]/Common7/IDE/ReferenceAssemblies/v4.0/
    """

    # Try explicit path first
    if ctx.attr.runtime_path:
        base_path = ctx.path(ctx.attr.runtime_path)
        if base_path.exists:
            return base_path
        else:
            fail("Specified VSTO runtime_path does not exist: {}".format(ctx.attr.runtime_path))

    # Auto-detect Visual Studio installation
    vs_editions = ["Enterprise", "Professional", "Community", "BuildTools"]
    vs_years = ["2022", "2019", "2017"]

    # Check common Visual Studio paths
    program_files_paths = [
        "C:/Program Files/Microsoft Visual Studio",
        "C:/Program Files (x86)/Microsoft Visual Studio",
    ]

    # Try both ReferenceAssemblies/v4.0 and PublicAssemblies
    subdirs = [
        "Common7/IDE/ReferenceAssemblies/v4.0",
        "Common7/IDE/PublicAssemblies",
    ]

    for program_files in program_files_paths:
        for year in vs_years:
            for edition in vs_editions:
                for subdir in subdirs:
                    runtime_path = "{}/{}/{}/{}".format(
                        program_files,
                        year,
                        edition,
                        subdir,
                    )

                    defpath = ctx.path(runtime_path)
                    if defpath.exists:
                        # Verify that key assemblies exist
                        common_dll = ctx.path(runtime_path + "/Microsoft.Office.Tools.Common.dll")
                        if common_dll.exists:
                            return defpath

    # Not found - provide helpful error
    fail("""
VSTO Runtime assemblies not found!

These assemblies are required for VSTO add-in builds. They are part of the
Visual Studio Tools for Office (VSTO) development tools.

To fix this:

Option 1: Install Visual Studio with Office Developer Tools
  - Install Visual Studio 2022, 2019, or 2017
  - Include "Office/SharePoint development" workload

Option 2: Specify explicit path in WORKSPACE:
  vsto_runtime_register(
      runtime_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/PublicAssemblies"
  )

Required files:
  - Microsoft.Office.Tools.Common.dll
  - Microsoft.Office.Tools.Excel.dll
  - Microsoft.Office.Tools.Word.dll
  - Microsoft.Office.Tools.Outlook.dll
  - Microsoft.Office.Tools.v4.0.Framework.dll
  - Microsoft.Office.Tools.dll
  - Microsoft.VisualStudio.Tools.Applications.Runtime.dll
""")

def _vsto_runtime_register_impl(ctx):
    """Implementation of vsto_runtime_register repository rule"""

    # Detect VSTO runtime path
    runtime_path = _detect_vsto_runtime_path(ctx)

    # List of VSTO runtime assemblies to import
    vsto_assemblies = [
        "Microsoft.Office.Tools.Common",
        "Microsoft.Office.Tools.Excel",
        "Microsoft.Office.Tools.Excel.v4.0.Utilities",
        "Microsoft.Office.Tools.Word",
        "Microsoft.Office.Tools.Outlook",
        "Microsoft.Office.Tools.v4.0.Framework",
        "Microsoft.Office.Tools",
        "Microsoft.VisualStudio.Tools.Applications.Runtime",
        "Microsoft.VisualStudio.Tools.Applications.ServerDocument",
    ]

    # Create BUILD file with individual net_import_library targets
    build_content = '''# VSTO Runtime Assemblies
package(default_visibility = ["//visibility:public"])

load("@rules_dotnet_framework//dotnet:defs.bzl", "net_import_library")

'''

    for assembly in vsto_assemblies:
        dll_path = ctx.path(str(runtime_path) + "/" + assembly + ".dll")
        if dll_path.exists:
            ctx.symlink(dll_path, assembly + ".dll")
            build_content += '''net_import_library(
    name = "{name}",
    src = "{name}.dll",
    version = "0.0.0.0",
)

'''.format(name = assembly)

    ctx.file("BUILD.bazel", build_content)

vsto_runtime_register = repository_rule(
    _vsto_runtime_register_impl,
    attrs = {
        "runtime_path": attr.string(
            doc = "Explicit path to VSTO runtime directory. If not specified, auto-detection will be attempted.",
        ),
    },
    doc = """
Registers VSTO runtime assemblies for add-in builds.

These assemblies are required for building VSTO add-ins and are automatically
injected by the net_vsto_addin rule.

Example usage in WORKSPACE:

    load("@rules_dotnet_framework//dotnet/private/vsto:vsto_runtime.bzl", "vsto_runtime_register")

    vsto_runtime_register(name = "vsto_runtime")

    # Or with explicit path:
    vsto_runtime_register(
        name = "vsto_runtime",
        runtime_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/PublicAssemblies",
    )
""",
)
