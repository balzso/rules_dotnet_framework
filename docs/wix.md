# WiX Toolset v5 Integration for VSTO Add-ins

This document describes how to build Windows Installer packages (.msi) for VSTO add-ins using WiX Toolset v5 and Bazel.

## Overview

The `rules_dotnet_framework` ruleset provides full integration with WiX Toolset v5, allowing you to:

- Build Windows Installer packages (.msi) directly from Bazel
- Automatically stage VSTO add-in files for installer builds
- Sign MSI packages with Authenticode certificates
- Preserve critical GUIDs for upgrade support
- Use standard WiX source files (.wxs) without modification

## Prerequisites

### Required Software

1. **Windows 10+** with .NET Framework 4.7+ installed
2. **Bazel 3.0+**
3. **.NET Framework SDK** (part of Windows SDK or Visual Studio)
4. **WiX Toolset v5** - Install via .NET tool:
   ```bash
   dotnet tool install --global wix
   ```
5. **Visual Studio 2017/2019/2022** with Office Developer Tools (for VSTO Utilities)

### Optional

- **Code signing certificate** (.pfx file or installed in certificate store) for Authenticode signing

## Quick Start

### 1. Configure WORKSPACE

```python
load("@rules_dotnet_framework//dotnet:defs.bzl",
     "net_register_sdk",
     "wix_register_sdk",
     "vsto_utilities_register",
     "dotnet_register_toolchains")

# Register .NET Framework SDK
net_register_sdk()

# Register WiX Toolset v5 (auto-detects wix.exe)
wix_register_sdk()

# Register VSTO Utilities (auto-detects Visual Studio)
vsto_utilities_register()

# Register toolchains
dotnet_register_toolchains()
```

### 2. Create VSTO Add-in

```python
# BUILD.bazel
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_vsto_addin")

net_vsto_addin(
    name = "MyExcelAddIn.dll",
    srcs = ["ThisAddIn.cs", "Ribbon1.cs"],
    office_app = "Excel",
    office_version = "2016",
    target_framework = "net472",
    generate_manifests = True,
)
```

### 3. Create Windows Installer

```python
# setup/BUILD.bazel
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_vsto_installer")

net_vsto_installer(
    name = "MyExcelAddInSetup.msi",
    vsto_addin = "//:MyExcelAddIn.dll",
    wxs_srcs = [
        "Product.wxs",
        "Files.wxs",
        "Registry.wxs",
    ],
    arch = "x86",
    product_version = "1.0.0",
    upgrade_code = "YOUR-UPGRADE-CODE-GUID-HERE",
    manufacturer = "Your Company",
    product_name = "My Excel Add-in",
)
```

### 4. Build

```bash
# Build the installer (this also builds the add-in)
bazel build //setup:MyExcelAddInSetup.msi
```

Output: `bazel-bin/setup/MyExcelAddInSetup.msi`

## Rules

### `wix_register_sdk()`

Repository rule that locates WiX Toolset v5.

**Location**: WORKSPACE file

**Attributes**:
- `name` (string, optional): Repository name. Default: "wix_sdk"
- `wix_path` (string, optional): Explicit path to wix.exe. If not specified, auto-detection is attempted.

**Auto-detection search order**:
1. .NET global tools: `~/.dotnet/tools/wix.exe`
2. NuGet global cache: `~/.nuget/packages/wix/[version]/tools/net6.0/any/wix.exe`

**Example**:

```python
# Auto-detect
wix_register_sdk()

# Explicit path
wix_register_sdk(
    wix_path = "C:/Users/YourUser/.dotnet/tools/wix.exe"
)
```

---

### `vsto_utilities_register()`

Repository rule that locates VSTO Utilities assemblies.

**Location**: WORKSPACE file

**Attributes**:
- `name` (string, optional): Repository name. Default: "vsto_utilities"
- `utilities_path` (string, optional): Explicit path to VSTO Utilities directory

**Auto-detection search order**:
- Visual Studio 2022/2019/2017
- Enterprise/Professional/Community/BuildTools editions
- Path: `Common7/IDE/ReferenceAssemblies/v4.0/`

**Required files**:
- Microsoft.Office.Tools.Common.v4.0.Utilities.dll
- Microsoft.Office.Tools.Excel.v4.0.Utilities.dll
- Microsoft.Office.Tools.Word.v4.0.Utilities.dll
- Microsoft.Office.Tools.Outlook.v4.0.Utilities.dll

**Example**:

```python
# Auto-detect
vsto_utilities_register()

# Explicit path
vsto_utilities_register(
    utilities_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/ReferenceAssemblies/v4.0"
)
```

---

### `wix_package()`

Low-level rule for building Windows Installer packages from WiX source files.

**Location**: BUILD file

**Attributes**:

- `name` (label, required): Name of the output MSI (must end with .msi)
- `srcs` (label_list, required): WiX source files (.wxs)
- `vsto_addin` (label, optional): VSTO add-in target to include (DotnetLibrary provider)
- `staging_dir` (label, optional): Explicit staging directory (tree artifact)
- `data` (label_list, optional): Additional data files (e.g., License.rtf, icons)
- `arch` (string, optional): Target architecture. Default: "x86". Values: x86, x64, ARM64
- `defines` (string_dict, optional): WiX preprocessor variables
- `bindpaths` (string_dict, optional): WiX bindpath mappings
- `extensions` (string_list, optional): WiX extension names
- `cert_file` (label, optional): PFX certificate file for signing
- `cert_password` (string, optional): Certificate password
- `cert_thumbprint` (string, optional): Certificate thumbprint (for certificate store)
- `timestamp_url` (string, optional): Timestamp server URL. Default: http://timestamp.digicert.com
- `sign_description` (string, optional): Description for Authenticode signature

**Example**:

```python
wix_package(
    name = "MyApp.msi",
    srcs = ["Product.wxs", "Files.wxs"],
    vsto_addin = ":MyAddIn.dll",
    data = ["License.rtf", "icon.ico"],
    arch = "x86",
    defines = {
        "ProductVersion": "1.0.0",
        "ProductCode": "*",  # Auto-generate
    },
    bindpaths = {
        "VsReferenceAssemblies": "../vsto_utilities",
    },
    extensions = ["WixToolset.UI.wixext"],
    cert_file = "certificate.pfx",
    cert_password = "password",
    sign_description = "My Application Installer",
)
```

---

### `net_vsto_installer()`

High-level convenience rule for building VSTO add-in installers.

**Location**: BUILD file

**Attributes**:

- `name` (label, required): Name of the output MSI (must end with .msi)
- `vsto_addin` (label, required): VSTO add-in target (net_vsto_addin)
- `wxs_srcs` (label_list, required): WiX source files (.wxs)
- `arch` (string, optional): Target architecture. Default: "x86"
- `product_version` (string, required): Product version (e.g., "1.0.0")
- `product_code` (string, optional): Product GUID or "*" for auto-generation. Default: "*"
- `upgrade_code` (string, required): Upgrade code GUID (required for upgrades)
- `manufacturer` (string, optional): Manufacturer name
- `product_name` (string, optional): Product name
- `extensions` (string_list, optional): WiX extensions. Default: ["WixToolset.UI.wixext"]
- `data` (label_list, optional): Additional data files
- `cert_file` (label, optional): PFX certificate file
- `cert_password` (string, optional): Certificate password
- `cert_thumbprint` (string, optional): Certificate thumbprint
- `timestamp_url` (string, optional): Timestamp server URL
- `sign_description` (string, optional): Authenticode signature description

**Automatic Configuration**:
- VSTO Utilities bindpath (`VsReferenceAssemblies`)
- Default WiX extensions (WixToolset.UI.wixext)
- Preprocessor defines (ProductVersion, ProductCode, UpgradeCode, etc.)

**Example**:

```python
net_vsto_installer(
    name = "MyExcelAddInSetup.msi",
    vsto_addin = "//:MyExcelAddIn.dll",
    wxs_srcs = [
        "Product.wxs",
        "Files.wxs",
        "Registry.wxs",
        "UI.wxs",
    ],
    data = ["License.rtf"],
    arch = "x86",
    product_version = "1.0.0",
    upgrade_code = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF",  # CRITICAL: Don't change!
    manufacturer = "My Company",
    product_name = "My Excel Add-in",
    extensions = [
        "WixToolset.UI.wixext",
        "WixToolset.Util.wixext",
    ],
    cert_file = "certificate.pfx",
    sign_description = "My Excel Add-in Installer",
)
```

## WiX Source Files (.wxs)

### Product.wxs Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
     xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui">

  <?define ProductName = "My Excel Add-in" ?>
  <?define ProductManufacturer = "My Company" ?>
  <?define UpgradeCode = "YOUR-GUID-HERE" ?>

  <Package Name="$(ProductName)"
           Manufacturer="$(ProductManufacturer)"
           Version="!(bind.FileVersion.MyAddIn.dll)"
           UpgradeCode="$(UpgradeCode)"
           Language="1033"
           Scope="perUserOrMachine">

    <ui:WixUI Id="WixUI_Advanced" />
    <UIRef Id="WixUI_ErrorProgressText" />

    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed."
                  Schedule="afterInstallInitialize" />

    <MediaTemplate EmbedCab="yes" />

    <Feature Id="ProductFeature"
             Title="My Excel Add-in"
             Level="1"
             AllowAdvertise="no">
      <ComponentGroupRef Id="ProductComponents" />
      <ComponentGroupRef Id="RegistryComponents" />
    </Feature>
  </Package>
</Wix>
```

### Files.wxs Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Fragment>
    <ComponentGroup Id="ProductComponents">
      <Component Id="MainDLL" Directory="APPLICATIONFOLDER" Guid="YOUR-COMPONENT-GUID">
        <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
        <File Id="MyAddIn.dll.manifest" Source="$(var.SourceDir)\MyAddIn.dll.manifest" />
        <File Id="MyAddIn.vsto" Source="$(var.SourceDir)\MyAddIn.vsto" />
      </Component>

      <!-- VSTO Utilities (from bindpath) -->
      <Component Id="VSTOUtilities.Common" Directory="APPLICATIONFOLDER" Guid="*">
        <File Id="VSTOUtilities.Common"
              Source="VsReferenceAssemblies\Microsoft.Office.Tools.Common.v4.0.Utilities.dll" />
      </Component>
      <Component Id="VSTOUtilities.Excel" Directory="APPLICATIONFOLDER" Guid="*">
        <File Id="VSTOUtilities.Excel"
              Source="VsReferenceAssemblies\Microsoft.Office.Tools.Excel.v4.0.Utilities.dll" />
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
```

### Registry.wxs Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Fragment>
    <ComponentGroup Id="RegistryComponents">
      <Component Id="RegistryEntries" Directory="APPLICATIONFOLDER" Guid="*">
        <RegistryKey Root="HKCU" Key="Software\Microsoft\Office\Excel\Addins\MyAddIn">
          <RegistryValue Type="string" Name="Description" Value="My Excel Add-in" />
          <RegistryValue Type="string" Name="FriendlyName" Value="My Excel Add-in" />
          <RegistryValue Type="integer" Name="LoadBehavior" Value="3" />
          <RegistryValue Type="string" Name="Manifest"
                         Value="[APPLICATIONFOLDER]MyAddIn.vsto|vstolocal" />
        </RegistryKey>
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
```

## File Staging

The `wix_package` and `net_vsto_installer` rules automatically stage VSTO add-in files:

**Staged Files**:
- Main VSTO assembly (.dll)
- PDB debug symbols (if available)
- Application manifest (.dll.manifest)
- Deployment manifest (.vsto)
- Transitive dependencies (NuGet packages)
- Additional runfiles (configs, etc.)

**WiX Variable**:
- `$(var.SourceDir)` points to the staging directory
- Use in .wxs files: `<File Source="$(var.SourceDir)\MyAddIn.dll" />`

**VSTO Utilities**:
- Not staged (they have `Private=False` in .csproj)
- Referenced via bindpath: `VsReferenceAssemblies`
- Use in .wxs: `<File Source="VsReferenceAssemblies\Microsoft.Office.Tools.Common.v4.0.Utilities.dll" />`

## Authenticode Signing

### Using PFX Certificate

```python
net_vsto_installer(
    name = "MySetup.msi",
    # ...
    cert_file = "certificate.pfx",
    cert_password = "password",
    timestamp_url = "http://timestamp.digicert.com",
    sign_description = "My Application Installer",
)
```

### Using Certificate Store

```python
net_vsto_installer(
    name = "MySetup.msi",
    # ...
    cert_thumbprint = "1137B034F812263E9A8E4B979F4551D8937B7562",
    timestamp_url = "http://timestamp.digicert.com",
    sign_description = "My Application Installer",
)
```

**Signing Process**:
1. MSI package is built
2. signtool.exe is invoked via signtool_wrapper
3. MSI is signed with SHA256 digest
4. Timestamp is applied from timestamp server
5. Signed MSI is returned as output

## GUID Management

### Critical GUIDs

**UpgradeCode GUID**:
- **MUST remain constant** across all versions
- Changing it breaks upgrade functionality
- Users will have multiple versions installed
- Set once and never change

**Component GUIDs**:
- Can be auto-generated (`Guid="*"`) for most components
- **MUST remain constant** for components that:
  - Contain the main VSTO assembly
  - Modify shared resources
  - Install fonts or COM objects
- Use explicit GUID for main DLL component

**Product GUID**:
- Can be auto-generated (`ProductCode="*"`)
- Changes automatically for each version
- Windows Installer uses this to track installations

### Example with Preserved GUIDs

```xml
<!-- Product.wxs -->
<?define UpgradeCode = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF" ?>

<!-- Files.wxs -->
<Component Id="MainDLL" Guid="91650F42-69E2-4DBC-8F83-C5EE73FC3E0E">
  <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
</Component>

<Component Id="SomeOtherComponent" Guid="*">
  <!-- Auto-generated GUID -->
</Component>
```

## WiX Extensions

Common WiX extensions for VSTO installers:

```python
extensions = [
    "WixToolset.UI.wixext",        # Standard UI dialogs
    "WixToolset.Util.wixext",      # Utility functions
    "WixToolset.NetFx.wixext",     # .NET Framework checks
]
```

**Using Extensions in .wxs**:

```xml
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
     xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui"
     xmlns:util="http://wixtoolset.org/schemas/v4/wxs/util"
     xmlns:netfx="http://wixtoolset.org/schemas/v4/wxs/netfx">
  <!-- ... -->
</Wix>
```

## Troubleshooting

### WiX Tool Not Found

**Error**: `WiX tool not found. Ensure wix_register_sdk() is called in WORKSPACE.`

**Solution**:
1. Install WiX: `dotnet tool install --global wix`
2. Verify: `wix --version`
3. Or specify explicit path in WORKSPACE:
   ```python
   wix_register_sdk(wix_path = "C:/Users/YourUser/.dotnet/tools/wix.exe")
   ```

### VSTO Utilities Not Found

**Error**: `VSTO Utilities assemblies not found!`

**Solution**:
1. Install Visual Studio with Office Developer Tools workload
2. Or specify explicit path:
   ```python
   vsto_utilities_register(
       utilities_path = "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/ReferenceAssemblies/v4.0"
   )
   ```

### WiX Compilation Errors

**Error**: `Unresolved reference to symbol 'Component:MyComponent'`

**Solution**: Check that all Component IDs referenced in Features exist in .wxs files.

**Error**: `The system cannot find the file specified: $(var.SourceDir)\MyFile.dll`

**Solution**: Ensure the file is included in the VSTO add-in's output or listed in `data` attribute.

### Signing Errors

**Error**: `SignTool Error: No certificates were found that met all the given criteria.`

**Solution**: Verify certificate thumbprint is correct or PFX file path is valid.

## Best Practices

1. **Always preserve UpgradeCode**: Never change it across versions
2. **Use explicit GUIDs for main components**: Prevents upgrade issues
3. **Sign your MSI**: Required for enterprise deployment
4. **Use timestamping**: Signatures remain valid after certificate expires
5. **Test upgrades**: Always test upgrading from previous versions
6. **Version numbering**: Use semantic versioning (Major.Minor.Patch)
7. **Validate .wxs files**: Use WiX validators before committing
8. **Document GUIDs**: Keep a record of all critical GUIDs

## Advanced Topics

### Custom Actions

Add custom actions in .wxs files as usual:

```xml
<CustomAction Id="MyCustomAction"
              BinaryKey="CustomActionDll"
              DllEntry="MyFunction" />
```

### Localization

Use WiX culture support:

```python
net_vsto_installer(
    # ...
    extensions = ["WixToolset.UI.wixext"],
    # Add culture support in .wxs files
)
```

### Burn Bootstrapper

For creating setup.exe bundles, use WiX Burn (requires additional configuration).

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Build Installer
  run: |
    bazel build //setup:MySetup.msi
    cp bazel-bin/setup/MySetup.msi artifacts/
```

## Examples

See the complete example project:
- `../excel-add-in/BUILD.bazel` - VSTO add-in configuration
- `../excel-add-in/Setup.Wix/BUILD.bazel` - Installer configuration
- `../excel-add-in/BAZEL-MIGRATION.md` - Detailed migration guide

## References

- [WiX Toolset v5 Documentation](https://wixtoolset.org/docs/)
- [VSTO Development Guide](vsto.md)
- [Bazel Build System](https://bazel.build/docs)
- [Windows Installer Best Practices](https://docs.microsoft.com/en-us/windows/win32/msi/)
