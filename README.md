# Bazel Rules for .NET Framework, VSTO, and WiX

Bazel build rules for .NET Framework, VSTO Office add-ins, and WiX installers on Windows.

## Status

This is a fork of [rules_dotnet](https://github.com/bazelbuild/rules_dotnet) specifically for .NET Framework development. The original project dropped Framework support in favor of .NET Core. This repository maintains .NET Framework support for projects that require it.

**Supported:**
- .NET Framework 4.7, 4.7.1, 4.7.2
- Windows only
- C# compilation
- NUnit3 and xUnit testing
- NuGet package management
- **VSTO (Visual Studio Tools for Office) add-in development**
- **WiX Toolset v5 for Windows Installer (.msi) packages**

**Not Supported:**
- .NET Core / .NET 5+ (use the official [rules_dotnet](https://github.com/bazelbuild/rules_dotnet) instead)
- Mono
- F#
- Cross-platform builds

## Prerequisites

**Windows Requirements:**
- Windows 10 or later
- .NET Framework 4.7+ installed
- Windows SDK with .NET Framework tools
- Bazel 3.0+

**Important Windows Considerations:**
1. **Long Paths**: Bazel creates long paths. Enable long path support in Windows:
   - Windows 10 1607+: Set `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled` to 1
   - Or use Group Policy: "Enable Win32 long paths"

2. **TMP Directory**: Set TMP environment variable to a short path (e.g., `C:\TEMP`) due to MSVC compiler limitations:
   ```cmd
   set TMP=C:\TEMP
   set TEMP=C:\TEMP
   ```

3. **Symbolic Links**: May require elevated permissions or Windows 10 Developer Mode

## Quick Start

### 1. Add to your WORKSPACE

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_dotnet_framework",
    remote = "https://github.com/balzso/rules_dotnet_framework.git",
    branch = "main",
)

load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_repositories")
dotnet_repositories()

load(
    "@rules_dotnet_framework//dotnet:defs.bzl",
    "dotnet_register_toolchains",
    "dotnet_repositories_nugets",
    "net_register_sdk",
)

# Register .NET Framework SDK
net_register_sdk()

# Register toolchains
dotnet_register_toolchains()

# Load NuGet packages for testing (optional)
dotnet_repositories_nugets()
```

### 2. Create a BUILD file

```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_library", "net_binary")

net_library(
    name = "MyLibrary.dll",
    srcs = ["MyClass.cs"],
    target_framework = "net472",
)

net_binary(
    name = "MyApp.exe",
    srcs = ["Program.cs"],
    deps = [":MyLibrary.dll"],
    target_framework = "net472",
)
```

### 3. Build

```bash
bazel build //:MyApp.exe
```

## Available Rules

### Library Rules
- `net_library` - Build a .NET Framework class library (.dll)
- `net_import_library` - Import a precompiled .NET Framework assembly

### Binary Rules
- `net_binary` - Build a .NET Framework executable (.exe)
- `net_import_binary` - Import a precompiled .NET Framework executable

### Test Rules
- `net_nunit3_test` - NUnit3 test
- `net_xunit_test` - xUnit test

### Resource Rules
- `net_resx` - Compile .resx resource files
- `net_resource` - Embed resources into assemblies

### VSTO Rules
- `net_vsto_addin` - Build VSTO (Office) add-ins with automatic PIA and manifest generation

### WiX Rules
- `wix_package` - Build Windows Installer (.msi) packages
- `net_vsto_installer` - High-level rule for VSTO add-in installers

### Other Rules
- `net_gac` - Reference assemblies from the Global Assembly Cache (GAC)
- `net_com_library` - Import COM libraries via tlbimp

## NuGet Package Management

Use the `nuget2bazel` tool to manage NuGet dependencies:

```bash
# Build the tool
bazel build //tools/nuget2bazel:nuget2bazel.exe

# Add a NuGet package
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3

# Remove a package
bazel run //tools/nuget2bazel:nuget2bazel.exe -- delete -p . Newtonsoft.Json
```

This generates `nuget_package()` rules in your WORKSPACE or .bzl files.

## Target Frameworks

Specify the target framework version:

```python
net_library(
    name = "MyLib.dll",
    srcs = ["MyClass.cs"],
    target_framework = "net472",  # or "net47", "net471"
)
```

## Examples

See the `tests/examples/` directory for working examples:
- `example_binary/` - Simple console application
- `example_lib/` - Class library
- `example_test/` - NUnit3 tests
- `example_xunit/` - xUnit tests
- `example_resx/` - Resource file usage
- `example_vsto_excel/` - VSTO Excel add-in with ClickOnce manifests

## Documentation

- [VSTO Development Guide](docs/vsto.md)
- [WiX Integration Guide](docs/wix.md)
- [Migration Guide](MIGRATION.md)
- [NuGet Package Management](tools/nuget2bazel/README.rst)
- [Toolchain Configuration](dotnet/toolchains.rst)
- [Providers](dotnet/providers.rst)
- [Runtime Considerations](docs/runtime.rst)

## Differences from Official rules_dotnet

This fork differs from the official `rules_dotnet`:
- **Framework Only**: No .NET Core support
- **Windows Only**: Removed Mono and cross-platform support
- **Simplified**: Removed Core-specific features
- **Stable**: Based on proven d672bdb commit from rules_dotnet

## Migration from .NET Core rules

If migrating from the official rules_dotnet:
1. Change `csharp_library` → `net_library`
2. Change `csharp_binary` → `net_binary`
3. Change `csharp_nunit3_test` → `net_nunit3_test`
4. Add `target_framework = "net472"` to all rules
5. Update WORKSPACE to use `net_register_sdk()`

## License

Apache License 2.0 (same as original rules_dotnet)

## Contributing

This is a focused fork for .NET Framework support. For .NET Core/5+, please use the official [rules_dotnet](https://github.com/bazelbuild/rules_dotnet) project.

## Credits

Based on the excellent work by the [rules_dotnet](https://github.com/bazelbuild/rules_dotnet) team, specifically the state at commit d672bdb before Framework support was removed.
