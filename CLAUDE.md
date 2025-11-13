# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**rules_dotnet_framework** is a Bazel ruleset for building .NET Framework projects on Windows. This is a fork of the original rules_dotnet, focused exclusively on .NET Framework 4.7-4.7.2 support.

**Key differences from original rules_dotnet:**
- .NET Framework ONLY (no .NET Core/5+)
- Windows ONLY (no Mono, no cross-platform)
- Supports net47, net471, net472 only
- Based on d672bdb commit (Jan 2021, before Framework support was removed)
- **NEW: VSTO (Visual Studio Tools for Office) add-in development support**
- **NEW: WiX Toolset v5 integration for building Windows Installer (.msi) packages**

## Building and Testing

### Prerequisites
- Windows 10+ with .NET Framework 4.7+ installed
- Windows SDK with .NET Framework developer tools
- Bazel 3.0+
- TMP environment variable set to short path (e.g., `C:\TEMP`)

### Common Commands

**Build a library:**
```bash
bazel build //tests/examples/example_lib:MyClass.dll
```

**Build an executable:**
```bash
bazel build //tests/examples/example_binary:hello.exe
```

**Run tests:**
```bash
bazel test //tests/examples/example_test:...
```

**Build nuget2bazel tool:**
```bash
bazel build //tools/nuget2bazel:nuget2bazel.exe
```

**Add NuGet package:**
```bash
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3
```

**Build VSTO add-in:**
```bash
bazel build //tests/examples/example_vsto_excel:ExampleVstoExcel.dll
```

**Build Windows Installer (.msi):**
```bash
bazel build //path/to/setup:MyInstaller.msi
```

## Architecture

### Core Components

**dotnet/defs.bzl**: Main public API
- `net_library` - Build .NET Framework class libraries
- `net_binary` - Build .NET Framework executables
- `net_vsto_addin` - Build VSTO (Office) add-ins
- `net_nunit3_test`, `net_xunit_test` - Test rules
- `net_resx`, `net_resource` - Resource handling
- `net_gac` - GAC assembly references
- `net_com_library` - COM interop
- `net_import_library`, `net_import_binary` - Import precompiled assemblies

**dotnet/private/providers.bzl**: Key providers
- `DotnetLibrary` - Represents a compiled .NET assembly with dependencies
- `DotnetResourceList` - Collection of embedded resources

**dotnet/private/net_toolchain.bzl**: .NET Framework toolchain
- Locates csc.exe (C# compiler) on Windows
- Finds .NET Framework reference assemblies
- Provides resgen.exe, tlbimp.exe, mage.exe, signtool.exe tools

**dotnet/private/sdk_net.bzl**: SDK detection
- Searches for .NET Framework SDK in standard Windows locations
- Typical paths:
  - `C:/Program Files (x86)/Microsoft SDKs/Windows/.../bin/NETFX ... Tools/`
  - `C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.7.x/`

**dotnet/private/actions/assembly.bzl**: Compilation dispatcher
- Routes to `assembly_net.bzl` for Framework builds

**dotnet/private/actions/assembly_net.bzl**: Framework compiler action
- Delegates to `assembly_common.bzl` with `kind = "net"`

**dotnet/private/actions/assembly_common.bzl**: Core compilation logic
- Builds csc.exe argument list
- Handles references, resources, defines, debug/release modes
- Creates parameter files for long command lines
- Executes compilation action

### Standard Library (stdlib)

**dotnet/stdlib.net/**: Framework assemblies for each version
- `net47/` - .NET Framework 4.7 assemblies
- `net471/` - .NET Framework 4.7.1 assemblies
- `net472/` - .NET Framework 4.7.2 assemblies

Each directory contains:
- `BUILD.bazel` - Bazel build file with `net_import_library` rules
- `generated.bzl` - List of all framework assemblies (mscorlib.dll, System.dll, etc.)

These use Microsoft.NETFramework.ReferenceAssemblies NuGet packages.

### NuGet Package Management

**tools/nuget2bazel/**: C# tool for managing NuGet dependencies
- `Program.cs` - Entry point, command routing
- `AddCommand.cs` - Add packages
- `DeleteCommand.cs` - Remove packages
- `SyncCommand.cs` - Synchronize packages
- `WorkspaceParser.cs` / `WorkspaceWriter.cs` - Modify WORKSPACE files
- `ProjectBazelManipulator.cs` - Modify .bzl files

Generates `nuget_package()` rules with:
- Package name, version, SHA256
- Core library references
- Dependencies
- Runtime files (for native dependencies)

### Launchers

**dotnet/tools/launcher_net/**: Windows executable launcher
- `main.c` - C program that launches .NET Framework assemblies
- Uses LoadLibrary/GetProcAddress to invoke CLR
- Passes command-line arguments to managed code

**dotnet/tools/launcher_net_nunit3/**: NUnit3 test launcher
- Wraps NUnit3 test execution

**dotnet/tools/launcher_net_xunit/**: xUnit test launcher
- Wraps xUnit test execution

### Resource Handling

**dotnet/private/actions/resx.bzl**: Resource compilation dispatcher

**dotnet/private/actions/resx_net.bzl**: Framework resource compilation
- Uses resgen.exe to compile .resx files to .resources
- Embeds .resources into assemblies

**tools/simpleresgen/**: Custom resource generator (alternative to resgen.exe)
- Pure C# implementation for resource compilation

### COM Interop

**dotnet/private/actions/com_ref_net.bzl**: COM reference handling
- Uses tlbimp.exe to generate interop assemblies from COM type libraries

**dotnet/tools/tlbimp_wrapper/**: Wrapper around tlbimp.exe
- Ensures proper tool execution in Bazel sandbox

## Rule Implementation Pattern

All .NET Framework rules follow this pattern:

1. **Rule definition** (`dotnet/private/rules/library.bzl`, `binary.bzl`, `test.bzl`)
   - Validates inputs (e.g., `.dll` or `.exe` extension required)
   - Calls `dotnet_context()` to get toolchain
   - Calls `dotnet.actions.assembly()` for compilation
   - Returns `[DotnetLibrary, DefaultInfo]` providers

2. **Context creation** (`dotnet/private/context.bzl`)
   - `dotnet_context(ctx)` - Creates context with toolchain access
   - Provides `dotnet.actions`, `dotnet.mcs` (compiler), `dotnet.tools`

3. **Compilation** (`dotnet/private/actions/assembly_common.bzl`)
   - Builds /out, /target, /reference, /resource arguments
   - Creates parameter file (@params.txt) for long command lines
   - Executes csc.exe via launcher
   - Returns `DotnetLibrary` provider

## Build Rule Requirements

**Naming convention**: All targets MUST include file extension:
```python
net_library(
    name = "MyLib.dll",  # MUST end with .dll
    srcs = ["MyClass.cs"],
)

net_binary(
    name = "MyApp.exe",  # MUST end with .exe
    srcs = ["Program.cs"],
)
```

**Target framework**: Specify Framework version (defaults to net472 if not provided):
```python
net_library(
    name = "MyLib.dll",
    srcs = ["MyClass.cs"],
    target_framework = "net471",  # or "net47", "net472"
)
```

## Windows-Specific Considerations

**Long paths**: Bazel creates deep directory structures
- Enable long path support in Windows 10+
- Registry: `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled = 1`

**TMP directory**: Set to short path due to MSVC limitations
- `set TMP=C:\TEMP`
- `set TEMP=C:\TEMP`

**Symbolic links**: May require Developer Mode or elevated permissions

**Sandboxing**: .NET Framework SDK detection may not work with strict sandboxing
- Use `--spawn_strategy=standalone` if encountering SDK detection issues

**Global Assembly Cache (GAC)**: Can reference assemblies from GAC
```python
net_gac(
    name = "system_web",
    assembly = "System.Web",
    version = "4.0.0.0",
)
```

## Common Development Tasks

**Adding a new library:**
1. Create BUILD file in library directory
2. Add `net_library` rule with `.dll` name
3. List all `.cs` source files
4. Specify dependencies in `deps`

**Adding NuGet package:**
1. Build nuget2bazel: `bazel build //tools/nuget2bazel:nuget2bazel.exe`
2. Run: `bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . PackageName Version`
3. Reference in BUILD: `deps = ["@packagename//:lib"]`

**Creating tests:**
1. Add `net_nunit3_test` or `net_xunit_test` rule
2. Include test framework dependency: `@nunit//:lib` or `@xunit.assert//:lib`
3. Run: `bazel test //path/to:test.dll`

## Testing Structure

**tests/examples/**: Working example projects
- `example_binary/` - Console application
- `example_lib/` - Class library
- `example_test/` - NUnit3 tests
- `example_xunit/` - xUnit tests
- `example_resx/` - Resource files
- `example_tool/` - Tool/utility program
- `example_transitive_lib/` - Transitive dependency example

**tests/tools/nuget2bazel/**: Tests for nuget2bazel tool
- Unit tests for NuGet package management functionality

## Important Files to Understand

**WORKSPACE**: Repository dependencies and SDK registration
- `net_register_sdk()` - Locates .NET Framework SDK
- `dotnet_register_toolchains()` - Registers Framework toolchains
- `dotnet_repositories_nugets()` - Test framework NuGet packages

**dotnet/defs.bzl**: Public API exports
- All user-facing rules are exported here

**dotnet/platform/list.bzl**: Platform and Framework definitions
- `DOTNET_NET_FRAMEWORKS` - Supported Framework versions
- Platform constraints for toolchain selection

**dotnet/toolchain/toolchains.bzl**: Toolchain registration
- Maps OS/arch/framework combinations to toolchains

## Troubleshooting

**SDK not found**:
- Check .NET Framework 4.7+ is installed
- Check Windows SDK is installed
- Verify paths in `dotnet/private/sdk_net.bzl`

**Long path errors**:
- Enable long path support in Windows
- Set TMP to shorter path

**Compilation errors**:
- Check target_framework matches installed Framework
- Verify all dependencies are correct
- Check for missing NuGet packages

**Sandboxing issues**:
- Try `--spawn_strategy=standalone`
- Some tools (tlbimp, resgen) may have sandbox issues

## VSTO Development

**NEW:** This fork now supports VSTO (Visual Studio Tools for Office) add-in development!

### Quick Start

Build a VSTO add-in:
```python
net_vsto_addin(
    name = "MyExcelAddIn.dll",
    srcs = ["ThisAddIn.cs", "Ribbon1.cs"],
    office_app = "Excel",
    office_version = "2016",
    target_framework = "net472",
    keyfile = "MyAddIn.snk",
)
```

### VSTO Components

**dotnet/private/rules/vsto_addin.bzl**: `net_vsto_addin` rule
- Builds VSTO add-ins with automatic Office PIA and VSTO runtime dependencies
- Supports Excel, Word, Outlook, PowerPoint
- Generates ClickOnce manifests (.manifest, .vsto)
- Authenticode signing support

**dotnet/private/vsto/**: VSTO infrastructure
- `vsto_runtime.bzl` - VSTO runtime detection and dependency management
- `office_pias.bzl` - Office PIA (Primary Interop Assembly) helpers

**dotnet/private/actions/**: Manifest generation and signing
- `manifest.bzl` - Application manifest generation (mage.exe)
- `deployment_manifest.bzl` - Deployment manifest (.vsto) generation
- `sign.bzl` - Authenticode signing (signtool.exe)

**dotnet/tools/**: VSTO tooling wrappers
- `mage_wrapper/` - Wrapper for mage.exe (Manifest Generation Tool)
- `signtool_wrapper/` - Wrapper for signtool.exe (Code Signing Tool)

**tools/nuget_packages/vsto_packages.bzl**: Office PIA NuGet packages
- Microsoft.Office.Interop.Excel
- Microsoft.Office.Interop.Word
- Microsoft.Office.Interop.Outlook
- Microsoft.Office.Interop.PowerPoint

### Requirements

- **VSTO Runtime**: Visual Studio 2010 Tools for Office Runtime (installed with VS)
- **Office PIAs**: Available via NuGet packages
- **Windows SDK**: For mage.exe and signtool.exe tools
- **Office Installation**: Excel, Word, Outlook, or PowerPoint for testing

### Example

See `tests/examples/example_vsto_excel/` for a complete Excel add-in example.

Full documentation: `docs/vsto.md`

## WiX Toolset v5 Integration

**NEW:** This fork now supports building Windows Installer packages (.msi) using WiX Toolset v5!

### Quick Start

Build a Windows Installer:
```python
net_vsto_installer(
    name = "MyExcelAddInSetup.msi",
    vsto_addin = ":MyExcelAddIn.dll",
    wxs_srcs = ["Product.wxs", "Files.wxs", "Registry.wxs"],
    arch = "x86",
    product_version = "1.0.0",
    upgrade_code = "YOUR-UPGRADE-CODE-GUID-HERE",  # CRITICAL: Never change!
    manufacturer = "My Company",
    product_name = "My Excel Add-in",
)
```

### WiX Components

**dotnet/private/sdk_wix.bzl**: WiX SDK repository rule
- Auto-detects wix.exe from .NET global tools or NuGet cache
- Supports explicit path override

**dotnet/private/vsto_utilities.bzl**: VSTO Utilities repository rule
- Auto-detects Visual Studio installation (2017/2019/2022)
- Locates Microsoft.Office.Tools.*.Utilities.dll files
- Required for VSTO installer builds

**dotnet/private/wix_toolchain.bzl**: WiX toolchain infrastructure
- Manages wix.exe tool and extensions

**dotnet/private/actions/**: WiX build actions
- `wix_stage.bzl` - File staging for WiX builds
- `wix_build.bzl` - WiX compilation (emit_wix_package functions)
- `sign.bzl` - MSI Authenticode signing (emit_sign_msi)

**dotnet/private/rules/**: User-facing rules
- `wix_package.bzl` - Generic WiX package rule
- `vsto_installer.bzl` - High-level VSTO installer rule

**dotnet/tools/wix_wrapper/**: Wrapper for wix.exe
- Enables proper Bazel sandbox execution
- Follows existing pattern (mage_wrapper, signtool_wrapper)

### Requirements

- **WiX Toolset v5**: Install via `dotnet tool install --global wix`
- **Visual Studio**: With Office Developer Tools (for VSTO Utilities)
- **Windows SDK**: For signtool.exe (Authenticode signing)

### Example

Complete example project: `../excel-add-in/`

**VSTO Add-in** (`BUILD.bazel`):
```python
net_vsto_addin(
    name = "MyExcelAddIn.dll",
    srcs = ["ThisAddIn.cs", "Ribbon1.cs"],
    office_app = "Excel",
    office_version = "2016",
    target_framework = "net472",
)
```

**Windows Installer** (`Setup.Wix/BUILD.bazel`):
```python
net_vsto_installer(
    name = "MyExcelAddInSetup.msi",
    vsto_addin = "//:MyExcelAddIn.dll",
    wxs_srcs = ["Product.wxs", "Files.wxs", "Registry.wxs"],
    data = ["License.rtf"],
    arch = "x86",
    product_version = "1.0.0",
    upgrade_code = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF",
    manufacturer = "Step Forward Partners",
    extensions = ["WixToolset.UI.wixext"],
    cert_file = "certificate.pfx",  # Optional signing
)
```

**Build**:
```bash
# Single command builds add-in + installer
bazel build //Setup.Wix:MyExcelAddInSetup.msi
```

### Key Features

- **Automatic file staging**: Mimics MSBuild's bin\Release structure
- **VSTO Utilities bundling**: Auto-located from Visual Studio installation
- **Authenticode signing**: Support for PFX files and certificate store
- **GUID preservation**: Critical for upgrade functionality
- **WiX extensions**: Full support for WixToolset.UI.wixext, WixToolset.Util.wixext, etc.
- **Pure Bazel**: No MSBuild or .wixproj files needed

### Critical: GUID Management

**UpgradeCode**: MUST remain constant across all versions. Changing it breaks upgrade functionality!

```python
upgrade_code = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF",  # NEVER CHANGE!
```

**Component GUIDs**: Main VSTO DLL component should have explicit GUID:

```xml
<Component Id="MainDLL" Guid="91650F42-69E2-4DBC-8F83-C5EE73FC3E0E">
  <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
</Component>
```

### WiX Source Files

WiX `.wxs` files can be used without modification:
- `$(var.SourceDir)` points to staging directory (set automatically)
- `VsReferenceAssemblies` bindpath for VSTO Utilities (set automatically)
- Standard WiX v5 syntax

Full documentation: `docs/wix.md`

## Documentation

- README.md - Quick start and overview
- docs/vsto.md - **NEW:** VSTO development guide
- docs/wix.md - **NEW:** WiX Toolset v5 integration guide
- dotnet/toolchains.rst - Toolchain configuration details
- dotnet/providers.rst - Provider documentation
- dotnet/core.rst - API reference (some Core content, but patterns apply)
- tools/nuget2bazel/README.rst - NuGet tool documentation

## Migration Notes

This fork is based on d672bdb (Jan 2021). If cherry-picking fixes from upstream rules_dotnet:
- Focus on bug fixes, not new features
- Avoid anything related to .NET Core/5+
- Test thoroughly on Windows .NET Framework

For .NET Core/5+ projects, use the official rules_dotnet instead.
