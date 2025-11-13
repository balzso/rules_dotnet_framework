"""VSTO Runtime detection and import infrastructure"""

load("@rules_dotnet//dotnet:defs.bzl", "net_import_library")

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
