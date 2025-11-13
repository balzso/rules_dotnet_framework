# VSTO Development Guide

This guide explains how to build VSTO (Visual Studio Tools for Office) add-ins using rules_dotnet_framework.

## Overview

VSTO add-ins are .NET Framework assemblies that extend Microsoft Office applications (Excel, Word, Outlook, PowerPoint). This ruleset provides the `net_vsto_addin` rule to build these add-ins using Bazel.

## Prerequisites

### System Requirements

1. **Windows 10+** with .NET Framework 4.7+ installed
2. **Microsoft Office** 2013 or later
3. **VSTO Runtime** (Visual Studio 2010 Tools for Office Runtime)
   - Installed automatically with Visual Studio
   - Or download from Microsoft: [VSTO Runtime](https://www.microsoft.com/en-us/download/details.aspx?id=105522)
4. **Bazel** 3.0+

### Development Tools

- **Windows SDK** with .NET Framework developer tools (for mage.exe, signtool.exe)
- **Visual Studio** (recommended for VSTO runtime assemblies)
- **Code signing certificate** (optional, for production deployment)

## Quick Start

### 1. Configure WORKSPACE

Add Office PIA NuGet packages to your WORKSPACE:

```python
load("@io_bazel_rules_dotnet//tools/nuget_packages:vsto_packages.bzl", "vsto_nuget_packages")

# Register Office Primary Interop Assemblies
vsto_nuget_packages()
```

The VSTO runtime assemblies will be automatically detected from your Visual Studio installation.

### 2. Create Your Add-in

Create a simple Excel add-in:

**ThisAddIn.cs:**
```csharp
using System;
using Excel = Microsoft.Office.Interop.Excel;
using Microsoft.Office.Tools.Excel;

namespace MyExcelAddIn
{
    public partial class ThisAddIn
    {
        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            // Add-in initialization
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            // Add-in cleanup
        }

        #region VSTO generated code
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisAddIn_Startup);
            this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
        }
        #endregion
    }
}
```

### 3. Create BUILD File

**BUILD:**
```python
load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_vsto_addin")

net_vsto_addin(
    name = "MyExcelAddIn.dll",
    srcs = [
        "ThisAddIn.cs",
        "Ribbon1.cs",
    ],
    office_app = "Excel",
    office_version = "2016",
    target_framework = "net472",
    keyfile = "MyAddIn.snk",  # Optional: strong name signing
    deps = [
        "@microsoft.office.interop.excel//:lib",
        # VSTO runtime deps added automatically
    ],
)
```

### 4. Build

```bash
bazel build //:MyExcelAddIn.dll
```

## Rule Reference: net_vsto_addin

The `net_vsto_addin` rule builds VSTO add-ins with automatic configuration for Office and VSTO dependencies.

### Attributes

#### Standard .NET Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | **Required**. Target name, must end with `.dll` |
| `srcs` | label_list | **Required**. C# source files (`.cs`) |
| `deps` | label_list | Additional dependencies (DotnetLibrary providers) |
| `resources` | label_list | Embedded resources (DotnetResourceList providers) |
| `target_framework` | string | .NET Framework version (`net47`, `net471`, `net472`). Default: `net472` |
| `keyfile` | label | Strong name key file (`.snk`) |
| `version` | string | Assembly version (e.g., `"1.0.0.0"`) |
| `defines` | string_list | Preprocessor defines |
| `unsafe` | bool | Enable unsafe code compilation |
| `data` | label_list | Runtime data files |

#### VSTO-Specific Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `office_app` | string | **Required**. Target Office application: `"Excel"`, `"Word"`, `"Outlook"`, `"PowerPoint"` |
| `office_version` | string | Minimum Office version: `"2013"`, `"2016"`, `"2019"`, `"2021"`, `"365"`. Default: `"2016"` |
| `generate_manifests` | bool | Generate ClickOnce manifests (`.manifest`, `.vsto`). Default: `True` |
| `install_url` | string | Network deployment URL (optional) |
| `signing_cert` | label | PFX certificate file for Authenticode signing (optional) |
| `cert_password` | string | Certificate password (optional) |

### Automatic Dependencies

The `net_vsto_addin` rule automatically adds dependencies based on `office_app`:

**Excel:**
- `Microsoft.Office.Interop.Excel` (PIA)
- `Microsoft.Office.Tools.Excel` (VSTO)
- `Microsoft.Office.Tools.Excel.v4.0.Utilities`
- `Microsoft.Office.Tools.Common`
- `Microsoft.Office.Tools.v4.0.Framework`
- `Microsoft.Office.Tools`
- `Microsoft.VisualStudio.Tools.Applications.Runtime`

**Word:**
- `Microsoft.Office.Interop.Word` (PIA)
- `Microsoft.Office.Tools.Word` (VSTO)
- Plus common VSTO assemblies

**Outlook:**
- `Microsoft.Office.Interop.Outlook` (PIA)
- `Microsoft.Office.Tools.Outlook` (VSTO)
- Plus common VSTO assemblies

**PowerPoint:**
- `Microsoft.Office.Interop.PowerPoint` (PIA)
- Plus common VSTO assemblies

## VSTO Project Structure

### Recommended File Organization

```
my_excel_addin/
├── BUILD
├── ThisAddIn.cs        # Main add-in entry point
├── Ribbon1.cs          # Custom Ribbon UI (optional)
├── Globals.cs          # Global add-in accessor (optional)
├── MyAddIn.snk         # Strong name key (optional)
└── README.md
```

### Required Code Patterns

#### ThisAddIn Class

All VSTO add-ins need a `ThisAddIn` class with `Startup` and `Shutdown` handlers:

```csharp
public partial class ThisAddIn
{
    private void ThisAddIn_Startup(object sender, System.EventArgs e)
    {
        // Initialization code
    }

    private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
    {
        // Cleanup code
    }

    #region VSTO generated code
    private void InternalStartup()
    {
        this.Startup += new System.EventHandler(ThisAddIn_Startup);
        this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
    }
    #endregion
}
```

#### Globals Helper (Optional)

For accessing the add-in instance from other classes:

```csharp
internal static class Globals
{
    private static ThisAddIn _thisAddIn;

    internal static ThisAddIn ThisAddIn
    {
        get { return _thisAddIn ?? (_thisAddIn = new ThisAddIn()); }
        set { _thisAddIn = value; }
    }
}
```

## Manifest Generation

### Application Manifest

The application manifest (`.dll.manifest`) describes the add-in assembly and its dependencies. Generated automatically by `mage.exe`.

### Deployment Manifest

The deployment manifest (`.vsto`) points to the application manifest and provides version/update information. Also generated by `mage.exe`.

### Signing Manifests

For production deployment, manifests must be signed with an Authenticode certificate:

```python
net_vsto_addin(
    name = "MyAddIn.dll",
    # ...
    signing_cert = "cert.pfx",
    cert_password = "password",  # Or use certificate store
)
```

Signing uses `signtool.exe` from Windows SDK.

## Deployment

### Development Deployment

For testing during development:

1. **Build the add-in**:
   ```bash
   bazel build //:MyAddIn.dll
   ```

2. **Register via registry**:
   ```reg
   [HKEY_CURRENT_USER\Software\Microsoft\Office\Excel\Addins\MyAddIn]
   "Description"="My Excel Add-in"
   "FriendlyName"="My Add-in"
   "LoadBehavior"=dword:00000003
   "Manifest"="file:///C:/path/to/MyAddIn.vsto"
   ```

3. **Open Excel** and check **File > Options > Add-ins > COM Add-ins**

### Production Deployment

For production, use one of:

1. **ClickOnce deployment** (recommended)
   - Publish to web server
   - Users install via `.vsto` file
   - Automatic updates supported

2. **Windows Installer (MSI)**
   - Package add-in with WiX or similar
   - Install for all users
   - Registry entries created during install

3. **Group Policy deployment**
   - Deploy via Active Directory
   - Enterprise-wide rollout

## Advanced Topics

### Custom Ribbon UI

VSTO supports custom Ribbon UI via Ribbon XML or Ribbon Designer:

```csharp
using Microsoft.Office.Tools.Ribbon;

public partial class Ribbon1
{
    private void btnMyButton_Click(object sender, RibbonControlEventArgs e)
    {
        // Button logic
        Excel.Application excelApp = Globals.ThisAddIn.Application;
        // ...
    }
}
```

### Action Panes

Custom task panes for additional UI:

```csharp
private Microsoft.Office.Tools.CustomTaskPane myTaskPane;

private void ThisAddIn_Startup(object sender, System.EventArgs e)
{
    var taskPaneControl = new MyUserControl();
    myTaskPane = this.CustomTaskPanes.Add(taskPaneControl, "My Task Pane");
    myTaskPane.Visible = true;
}
```

### Smart Tags and Document Actions

VSTO supports smart tags and document-level actions for context-sensitive features.

### Data Caching

Cache data in documents using the `[Cached]` attribute (document-level customizations only).

## Troubleshooting

### VSTO Runtime Not Found

**Error:** "Could not find VSTO runtime assemblies"

**Solution:**
- Install Visual Studio with Office Developer Tools
- Or manually specify VSTO assembly paths in WORKSPACE

### Office PIAs Not Found

**Error:** "Could not find Microsoft.Office.Interop.Excel"

**Solution:**
- Ensure `vsto_nuget_packages()` is called in WORKSPACE
- Check NuGet package configuration

### Manifest Generation Fails

**Error:** "Could not find mage.exe"

**Solution:**
- Install Windows SDK
- Verify mage.exe location in `.NET Framework Tools` folder

### Signing Fails

**Error:** "Could not find signtool.exe"

**Solution:**
- Install Windows SDK
- Verify signtool.exe is in Windows SDK `bin` folder

### Add-in Not Loading

**Troubleshooting steps:**
1. Check registry entries are correct
2. Verify manifest paths are valid
3. Check Office Trust Center settings
4. Look for errors in Event Viewer (Application log)
5. Enable VSTO logging: `VSTO_LOGALERTS=1`, `VSTO_SUPPRESSDISPLAYALERTS=0`

## Examples

See `tests/examples/example_vsto_excel/` for a complete working example.

## Further Reading

- [VSTO Overview - Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/vsto/visual-studio-tools-for-office-runtime-overview)
- [Office Primary Interop Assemblies](https://learn.microsoft.com/en-us/visualstudio/vsto/office-primary-interop-assemblies)
- [ClickOnce Deployment for Office Solutions](https://learn.microsoft.com/en-us/visualstudio/vsto/deploying-an-office-solution-by-using-clickonce)
