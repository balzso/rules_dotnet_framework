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
| `resources` | label_list | Embedded resources (DotnetResourceList providers). Use with `net_resx` for .resx files or `net_resource` for binary/XML files |
| `config` | label | **NEW:** Application configuration file (`.config`). Automatically renamed to `<name>.dll.config` |
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

VSTO add-ins require two ClickOnce manifests for deployment:

### Application Manifest (.dll.manifest)

The application manifest describes the add-in assembly, its dependencies, and security requirements. Generated automatically when `generate_manifests = True`:

```python
net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs"],
    office_app = "Excel",
    generate_manifests = True,  # Generate .dll.manifest and .vsto files
)
```

**Output**: `MyAddIn.dll.manifest`

**Structure**:
- Assembly identity (name, version, processor architecture)
- Trust level (FullTrust for VSTO)
- Entry point class (e.g., `MyAddIn.ThisAddIn`)
- Office application customization (Excel, Word, etc.)
- Dependency declarations

**Generated by**: `emit_application_manifest()` function in `dotnet/private/actions/manifest.bzl`

### Deployment Manifest (.vsto)

The deployment manifest points to the application manifest and provides update information. Also generated automatically:

**Output**: `MyAddIn.vsto`

**Structure**:
- Deployment version and update settings
- Reference to application manifest (codebase path)
- Install/update behavior

**Generated by**: `emit_deployment_manifest()` function in `dotnet/private/actions/deployment_manifest.bzl`

### Manifest Signing

For production deployment, **both manifests must be signed** with an Authenticode certificate. Signing is performed automatically when certificate parameters are provided:

```python
net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs"],
    office_app = "Excel",
    generate_manifests = True,
    signing_cert = "MyAddIn.pfx",         # PFX certificate file
    cert_password = "YourPassword",       # Certificate password
)
```

**Signing Tool**: `mage.exe` from Windows SDK (Manifest Generation and Editing Tool)

**Process**:
1. Unsigned manifest XML is generated
2. Manifest is copied to Windows TEMP directory
3. **ReadOnly attribute is removed** (mage.exe creates files as ReadOnly but cannot sign ReadOnly files)
4. mage.exe signs the manifest in-place with the provided certificate
5. Signed manifest is copied to final Bazel output location
6. Temporary files are cleaned up

**Technical Details**:
- mage.exe has unusual behavior: it creates output files with ReadOnly attribute, then tries to sign them
- Without removing ReadOnly, signing fails with "Access denied" error
- The build system works around this by copying to TEMP, removing ReadOnly, signing in-place, then copying back
- Both .dll.manifest and .vsto files are signed independently
- Signing uses SHA256 digest algorithm
- Signatures are embedded as `<Signature>` blocks in the manifest XML

**Certificate Requirements**:
- Must be a valid Authenticode certificate
- PFX format (.pfx or .p12 file)
- Contains private key
- Password-protected (recommended) or unprotected

**Example signed manifest structure**:
```xml
<asmv1:assembly ...>
  <!-- Manifest content -->
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <SignedInfo>
      <CanonicalizationMethod Algorithm="..." />
      <SignatureMethod Algorithm="..." />
      <!-- ... -->
    </SignedInfo>
    <SignatureValue>BASE64-ENCODED-SIGNATURE</SignatureValue>
    <KeyInfo>
      <X509Data>
        <X509Certificate>BASE64-ENCODED-CERT</X509Certificate>
      </X509Data>
    </KeyInfo>
  </Signature>
</asmv1:assembly>
```

**Verification**:
```bash
# Build with signing
bazel build //:MyAddIn.dll

# Check if manifest is signed (look for Signature block)
cat bazel-bin/MyAddIn.dll.manifest | grep "<Signature"
```

**Troubleshooting Signing Issues**:

**Issue**: "Access to the path '...' is denied"
- **Cause**: mage.exe creates files as ReadOnly
- **Solution**: Automatically handled by the build system (copy to TEMP, remove ReadOnly, sign)
- **Workaround**: If still failing, check antivirus or file permissions

**Issue**: "mage.exe signing failed with exit code 2"
- **Cause**: Invalid certificate or incorrect password
- **Solution**: Verify certificate file exists and password is correct
- **Test**: Run mage.exe manually: `mage.exe -Sign MyAddIn.dll.manifest -CertFile cert.pfx -Password pwd -ToFile signed.manifest`

**Issue**: Manifest not signed (no Signature block)
- **Cause**: Certificate parameters not provided or signing disabled
- **Solution**: Add `signing_cert` and `cert_password` attributes to `net_vsto_addin`

**Self-Signed Certificates (Development Only)**:

For development/testing, you can create a self-signed certificate:

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=MyCompany Development" `
    -KeyUsage DigitalSignature `
    -FriendlyName "VSTO Development Certificate" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")

# Export to PFX
$certPassword = ConvertTo-SecureString -String "YourPassword" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "MyAddIn.pfx" -Password $certPassword
```

⚠️ **Warning**: Self-signed certificates are NOT trusted by default. For production deployment, use a certificate from a trusted Certificate Authority (CA).

**Production Certificates**:
- DigiCert Code Signing Certificate
- Sectigo Code Signing Certificate
- GlobalSign Code Signing Certificate
- Extended Validation (EV) certificates provide highest trust level

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

## Embedded Resources

### Overview

VSTO add-ins often need to embed binary files (XML, images, Excel templates, etc.) as resources. The `net_resource` rule enables embedding arbitrary files into your assembly.

### net_resource Rule

Embeds a single binary or text file as an embedded resource:

```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_resource", "net_vsto_addin")

net_resource(
    name = "Ribbon_xml",
    src = "Ribbon.xml",
    identifier = "MyAddIn.Ribbon.xml",
)

net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs"],
    resources = [":Ribbon_xml"],
    office_app = "Excel",
)
```

**Attributes:**
- `src` (label, required) - File to embed (any file type: .xml, .xlsx, .png, etc.)
- `identifier` (string, optional) - Resource identifier. If omitted, uses the filename

**Accessing embedded resources at runtime:**

```csharp
using System.Reflection;

// Load embedded resource
var assembly = Assembly.GetExecutingAssembly();
using (var stream = assembly.GetManifestResourceStream("MyAddIn.Ribbon.xml"))
{
    // Read resource content
}
```

### net_resource_multi Rule

Embeds multiple files at once:

```python
net_resource_multi(
    name = "templates",
    srcs = glob(["Resources/*.xlsx"]),
    identifierBase = "MyAddIn",  # Creates "MyAddIn.Resources.Template1.xlsx", etc.
)

net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs"],
    resources = [":templates"],
    office_app = "Excel",
)
```

**Attributes:**
- `srcs` (label_list, required) - Files to embed
- `identifierBase` (string) - Base identifier; file paths converted to dotted notation
- `fixedIdentifierBase` (string) - Fixed base identifier; each file uses this base + filename

### Common Use Cases

#### Ribbon XML

VSTO ribbon customization requires a Ribbon.xml file:

```python
net_resource(
    name = "Ribbon_xml",
    src = "Ribbon.xml",
    identifier = "MyAddIn.Ribbon.xml",  # Must match the identifier in code
)
```

In your Ribbon.cs:
```csharp
public string GetCustomUI(string RibbonID)
{
    return GetResourceText("MyAddIn.Ribbon.xml");
}

private static string GetResourceText(string resourceName)
{
    var asm = Assembly.GetExecutingAssembly();
    using (var stream = asm.GetManifestResourceStream(resourceName))
    using (var reader = new StreamReader(stream))
    {
        return reader.ReadToEnd();
    }
}
```

#### Excel Templates

Embed Excel template files for bulk import functionality:

```python
net_resource(
    name = "ImportTemplate",
    src = "Resources/BulkImport.xlsx",
    identifier = "MyAddIn.Resources.BulkImport.xlsx",
)

net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs", "BulkImport.cs"],
    resources = [":ImportTemplate"],
    office_app = "Excel",
)
```

Access at runtime:
```csharp
byte[] templateBytes;
using (var stream = Assembly.GetExecutingAssembly()
    .GetManifestResourceStream("MyAddIn.Resources.BulkImport.xlsx"))
{
    using (var ms = new MemoryStream())
    {
        stream.CopyTo(ms);
        templateBytes = ms.ToArray();
    }
}

// Save to temp file or use directly with Excel interop
string tempPath = Path.Combine(Path.GetTempPath(), "import_template.xlsx");
File.WriteAllBytes(tempPath, templateBytes);
```

#### Images and Icons

```python
net_resource(
    name = "app_icon",
    src = "Resources/icon.ico",
    identifier = "MyAddIn.Resources.icon.ico",
)
```

### Windows Forms Resources (.resx)

For Windows Forms resources (Designer-generated), use `net_resx`:

```python
net_resx(
    name = "MyForm_resx",
    src = "MyForm.resx",
    identifier = "MyAddIn.MyForm.resources",
)

net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["MyForm.cs", "MyForm.Designer.cs"],
    resources = [":MyForm_resx"],
    office_app = "Excel",
)
```

**Difference between net_resx and net_resource:**
- `net_resx` - Compiles .resx files to .resources using resgen.exe (for Windows Forms)
- `net_resource` - Embeds binary/text files directly (for XML, templates, images, etc.)

## Application Configuration

### config Attribute

The `config` attribute allows you to specify an application configuration file (`.config`) that will be automatically deployed alongside your add-in DLL.

```python
net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = ["ThisAddIn.cs"],
    config = "app.config",  # Automatically renamed to MyAddIn.dll.config
    office_app = "Excel",
)
```

### Common Configuration Scenarios

#### log4net Configuration

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <configSections>
    <section name="log4net" type="log4net.Config.Log4NetConfigurationSectionHandler, log4net"/>
  </configSections>

  <log4net>
    <root>
      <level value="ALL"/>
      <appender-ref ref="RollingFileAppender"/>
    </root>
    <appender name="RollingFileAppender" type="log4net.Appender.RollingFileAppender">
      <file value="${APPDATA}\MyCompany\MyAddIn\log.txt"/>
      <appendToFile value="true"/>
      <rollingStyle value="Size"/>
      <maxSizeRollBackups value="5"/>
      <maximumFileSize value="5MB"/>
      <layout type="log4net.Layout.PatternLayout">
        <conversionPattern value="%date [%thread] %level %logger - %message%newline"/>
      </layout>
    </appender>
  </log4net>
</configuration>
```

#### DPI Awareness

```xml
<configuration>
  <System.Windows.Forms.ApplicationConfigurationSection>
    <add key="DpiAwareness" value="PerMonitorV2"/>
  </System.Windows.Forms.ApplicationConfigurationSection>
</configuration>
```

#### Assembly Binding Redirects

```xml
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json"
                          publicKeyToken="30ad4fe6b2a6aeed"
                          culture="neutral"/>
        <bindingRedirect oldVersion="0.0.0.0-13.0.0.0" newVersion="13.0.0.0"/>
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

### Full Example with Config

```python
load("@rules_dotnet_framework//dotnet:defs.bzl",
     "net_resource", "net_vsto_addin")

# Ribbon XML
net_resource(
    name = "Ribbon_xml",
    src = "Ribbon.xml",
    identifier = "MyAddIn.Ribbon.xml",
)

# Excel templates
net_resource_multi(
    name = "templates",
    srcs = glob(["Resources/*.xlsx"]),
    identifierBase = "MyAddIn",
)

# Main add-in
net_vsto_addin(
    name = "MyAddIn.dll",
    srcs = [
        "ThisAddIn.cs",
        "Ribbon.cs",
        "BulkImport.cs",
    ],
    resources = [
        ":Ribbon_xml",
        ":templates",
    ],
    config = "app.config",  # log4net + DPI awareness + binding redirects
    deps = [
        "@log4net//:net",
        "@newtonsoft.json//:net",
    ],
    office_app = "Excel",
    target_framework = "net472",
)
```

This configuration ensures:
- ✅ Ribbon UI works (Ribbon.xml embedded)
- ✅ Template files available at runtime (.xlsx embedded)
- ✅ log4net logging configured (.dll.config deployed)
- ✅ High-DPI displays handled correctly
- ✅ NuGet package version conflicts resolved

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

### Manifest Signing Fails

**Error:** "mage.exe signing failed with exit code 2" or "Access to the path '...' is denied"

**Causes:**
- mage.exe creates files with ReadOnly attribute (handled automatically by build system)
- Invalid certificate or incorrect password
- Certificate file not found
- Antivirus blocking file operations

**Solutions:**
1. Verify certificate file exists and path is correct
2. Verify certificate password is correct
3. Check that `signing_cert` and `cert_password` attributes are set in `net_vsto_addin`
4. Test certificate manually:
   ```powershell
   # Test if certificate can be loaded
   $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("MyAddIn.pfx", "password")
   $cert.Subject  # Should display certificate subject
   ```
5. Temporarily disable antivirus and retry build
6. Ensure Windows SDK is installed (provides mage.exe)

**Note:** Manifest signing uses `mage.exe`, not `signtool.exe`. The `signtool.exe` tool is only used for MSI installer signing, not VSTO manifest signing.

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
