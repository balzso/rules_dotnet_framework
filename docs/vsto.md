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

Configure your WORKSPACE to enable automatic VSTO dependency injection:

```python
load(
    "@rules_dotnet_framework//dotnet:defs.bzl",
    "dotnet_register_toolchains",
    "dotnet_repositories_nugets",
    "vsto_runtime_register",
)

# 1. Register .NET toolchains
dotnet_register_toolchains()

# 2. Register NuGet repositories (includes Office PIAs)
dotnet_repositories_nugets()

# 3. Register VSTO Runtime
# Auto-detects VSTO runtime DLLs from Visual Studio or GAC
vsto_runtime_register(name = "vsto_runtime")
```

**That's it!** The automatic injection system will handle all VSTO and Office PIA dependencies. You don't need to manually add NuGet packages or reference VSTO runtime assemblies.

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

**BUILD.bazel:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_vsto_addin")

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
        # Office PIA and VSTO runtime dependencies are injected automatically!
        # Only add your custom dependencies here (e.g., NuGet packages, other libraries)
    ],
)
```

**Note:** The `office_app = "Excel"` attribute triggers automatic injection of:
- Excel Primary Interop Assembly (PIA)
- 8 VSTO runtime assemblies (interface + implementation DLLs)
- Standard .NET Framework libraries

No need to manually list VSTO dependencies! 🚀

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

⚡ **The `net_vsto_addin` rule automatically injects all required VSTO and Office PIA dependencies** based on the `office_app` attribute. You don't need to manually specify these in the `deps` list!

#### How It Works

The automatic injection system uses **private attributes** in the `net_vsto_addin` rule to automatically add the correct dependencies:

1. **Office PIA (Primary Interop Assemblies)** - Registered via `dotnet_repositories_nugets()`
2. **VSTO Runtime Assemblies** - Registered via `vsto_runtime_register()`
3. **Implementation DLLs** - Automatically discovered from Visual Studio or Windows GAC

#### Injected Dependencies by Office Application

**Excel:**
- `@microsoft.office.interop.excel//:net` (PIA)
- `@vsto_runtime//:Microsoft.Office.Tools.Common`
- `@vsto_runtime//:Microsoft.Office.Tools.Common.Implementation`
- `@vsto_runtime//:Microsoft.Office.Tools.Excel`
- `@vsto_runtime//:Microsoft.Office.Tools.Excel.Implementation`
- `@vsto_runtime//:Microsoft.Office.Tools.Excel.v4.0.Utilities`
- `@vsto_runtime//:Microsoft.Office.Tools.v4.0.Framework`
- `@vsto_runtime//:Microsoft.Office.Tools`
- `@vsto_runtime//:Microsoft.VisualStudio.Tools.Applications.Runtime`

**Word:**
- `@microsoft.office.interop.word//:net` (PIA)
- `@vsto_runtime//:Microsoft.Office.Tools.Common`
- `@vsto_runtime//:Microsoft.Office.Tools.Common.Implementation`
- `@vsto_runtime//:Microsoft.Office.Tools.Word`
- `@vsto_runtime//:Microsoft.Office.Tools.Word.Implementation`
- Plus common VSTO runtime assemblies

**Outlook:**
- `@microsoft.office.interop.outlook//:net` (PIA)
- `@vsto_runtime//:Microsoft.Office.Tools.Common`
- `@vsto_runtime//:Microsoft.Office.Tools.Common.Implementation`
- `@vsto_runtime//:Microsoft.Office.Tools.Outlook`
- `@vsto_runtime//:Microsoft.Office.Tools.Outlook.Implementation`
- Plus common VSTO runtime assemblies

**PowerPoint:**
- `@microsoft.office.interop.powerpoint//:net` (PIA)
- Plus common VSTO runtime assemblies (no application-specific DLLs)

#### VSTO Runtime Detection

The `vsto_runtime_register()` repository rule automatically detects VSTO runtime DLLs from:

1. **Visual Studio installation** - Searches in `Common7/IDE/ReferenceAssemblies/v4.0/` and `Common7/IDE/PublicAssemblies/`
2. **Windows GAC** (fallback) - Searches in `C:/Windows/Microsoft.NET/assembly/GAC_MSIL/` for `.Implementation` DLLs

**Example:** When you specify `office_app = "Excel"`, the build system automatically:
- Adds the Excel PIA from NuGet
- Adds 8 VSTO runtime assemblies (interface + implementation DLLs)
- Adds standard library dependencies (mscorlib, System.dll, etc.)

**No manual dependency management required!** ✨

#### COM Interop Type Embedding

**NEW:** Office PIAs are automatically embedded using `EmbedInteropTypes`!

When building VSTO add-ins, Office Primary Interop Assemblies (PIAs) are now **automatically embedded** into your add-in DLL using the C# `/link:` compiler flag. This provides several benefits:

**Benefits:**
- ✅ **Smaller deployment** - No need to distribute separate PIA DLLs
- ✅ **Version independence** - Eliminates PIA version conflicts
- ✅ **Simplified installation** - Fewer files to deploy
- ✅ **Better compatibility** - Works across different Office versions

**How it works:**
1. The build system detects Office PIAs by their label (e.g., `@microsoft.office.interop.excel`)
2. These assemblies are compiled with `/link:` instead of `/reference:`
3. Only the COM interfaces you actually use are embedded
4. CoClasses and implementations remain in Office at runtime

**Technical details:**
- The C# compiler embeds only interfaces, structures, enumerations, and delegates
- COM classes (CoClasses) cannot be directly instantiated - use interfaces instead
- Reduces deployment footprint significantly (typically 50KB+ reduction per PIA)
- Compatible with Office 2010 and later

**Example:** For Excel add-ins, `Microsoft.Office.Interop.Excel.dll` (~1MB) is NOT deployed. Instead, only the interfaces you use (~50KB) are embedded directly in your add-in DLL.

**Manual control:**
If you need to manually control type embedding for non-Office COM interop assemblies:

```python
net_import_library(
    name = "my_com_interop",
    src = "MyComInterop.dll",
    version = "1.0.0.0",
    embed_interop_types = True,  # Enable type embedding
)
```

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

## Automatic Dependency Injection Architecture

### Overview

The automatic dependency injection system eliminates the need to manually specify VSTO and Office PIA dependencies in your BUILD files. This is achieved through a combination of repository rules, private attributes, and runtime detection.

### Implementation Details

#### 1. Repository Rules

**`vsto_runtime_register`** (in `dotnet/private/vsto/vsto_runtime.bzl`)
- Auto-detects VSTO runtime DLLs from Visual Studio installation or Windows GAC
- Creates a `@vsto_runtime` repository with `net_import_library` targets
- Searches locations:
  - Visual Studio: `Common7/IDE/ReferenceAssemblies/v4.0/`
  - Visual Studio: `Common7/IDE/PublicAssemblies/`
  - Windows GAC: `C:/Windows/Microsoft.NET/assembly/GAC_MSIL/`
- Handles both interface DLLs and `.Implementation` DLLs (fallback to GAC)

**`dotnet_repositories_nugets`** (in `dotnet/private/nugets.bzl`)
- Registers Office PIA NuGet packages:
  - `@microsoft.office.interop.excel`
  - `@microsoft.office.interop.word`
  - `@microsoft.office.interop.outlook`
  - `@microsoft.office.interop.powerpoint`
- Uses `dotnet_nuget_new` to create `net_import_library` targets with `:net` suffix

#### 2. Private Attributes in `net_vsto_addin`

The `net_vsto_addin` rule (in `dotnet/private/rules/vsto_addin.bzl`) defines private attributes for each Office application:

```python
# Office PIA dependencies (from NuGet)
"_pia_excel_deps": attr.label_list(
    default = [Label("@microsoft.office.interop.excel//:net")],
    providers = [DotnetLibrary],
)

# VSTO runtime dependencies (from vsto_runtime repository)
"_vsto_excel_deps": attr.label_list(
    default = [
        Label("@vsto_runtime//:Microsoft.Office.Tools.Common"),
        Label("@vsto_runtime//:Microsoft.Office.Tools.Common.Implementation"),
        Label("@vsto_runtime//:Microsoft.Office.Tools.Excel"),
        Label("@vsto_runtime//:Microsoft.Office.Tools.Excel.Implementation"),
        # ... more assemblies
    ],
    providers = [DotnetLibrary],
)
```

Similar attributes exist for Word, Outlook, and PowerPoint.

#### 3. Dependency Injection Logic

In the `_vsto_addin_impl` function:

```python
# Get Office PIA dependencies based on office_app
pia_deps = []
if ctx.attr.office_app == "Excel":
    pia_deps = ctx.attr._pia_excel_deps
elif ctx.attr.office_app == "Word":
    pia_deps = ctx.attr._pia_word_deps
# ... other apps

# Get VSTO runtime dependencies based on office_app
vsto_deps = []
if ctx.attr.office_app == "Excel":
    vsto_deps = ctx.attr._vsto_excel_deps
elif ctx.attr.office_app == "Word":
    vsto_deps = ctx.attr._vsto_word_deps
# ... other apps

# Combine user deps with automatic VSTO/PIA deps + stdlib
all_deps = ctx.attr.deps + pia_deps + vsto_deps + ctx.attr._stdlib
```

The combined dependencies are then passed to the .NET compiler via the `dotnet.assembly()` provider.

### Benefits

✅ **Zero manual configuration** - No need to list VSTO/PIA dependencies in BUILD files
✅ **Environment portability** - Works on any machine with Visual Studio or VS Build Tools
✅ **Automatic version detection** - Uses the VSTO runtime version installed on the system
✅ **GAC fallback** - `.Implementation` DLLs loaded from GAC if not in VS directories
✅ **Type safety** - Bazel validates all dependencies at analysis time

### Verification

To verify automatic injection is working, check the compiler parameters:

```bash
# Build your add-in
bazel build //:MyAddIn.dll

# Check compiler parameters file
cat bazel-bin/MyAddIn.dll.param | grep "vsto_runtime"
```

You should see all VSTO runtime DLLs listed in the `/r:` references, even though they're not in your `deps` list!

### Troubleshooting Injection

**Issue:** Build fails with "Could not find @vsto_runtime//..."

**Solution:**
1. Verify Visual Studio is installed with Office Developer Tools
2. Check VSTO runtime DLLs exist in VS installation:
   ```powershell
   Get-ChildItem "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\ReferenceAssemblies\v4.0\" -Filter "Microsoft.Office.Tools*.dll"
   ```
3. Manually specify VSTO runtime path in WORKSPACE:
   ```python
   vsto_runtime_register(
       name = "vsto_runtime",
       runtime_path = "C:/path/to/vsto/runtime",
   )
   ```

**Issue:** Compilation errors for VSTO types (e.g., "AddInBase not found")

**Solution:**
- The `.Implementation` DLLs may be missing
- Check GAC contains implementation DLLs:
  ```powershell
  Get-ChildItem "C:\Windows\Microsoft.NET\assembly\GAC_MSIL" -Recurse -Filter "*Office.Tools*.Implementation.dll"
  ```
- Ensure `vsto_runtime_register` GAC fallback is working (check repository rule implementation)

## Examples

See `tests/examples/example_vsto_excel/` for a complete working example.

## Further Reading

- [VSTO Overview - Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/vsto/visual-studio-tools-for-office-runtime-overview)
- [Office Primary Interop Assemblies](https://learn.microsoft.com/en-us/visualstudio/vsto/office-primary-interop-assemblies)
- [ClickOnce Deployment for Office Solutions](https://learn.microsoft.com/en-us/visualstudio/vsto/deploying-an-office-solution-by-using-clickonce)
- [Bazel Rule Attributes](https://bazel.build/rules/lib/attr)
- [Bazel Repository Rules](https://bazel.build/extending/repo)
