# Migration Guide

This guide helps you migrate to **rules_dotnet_framework** from various scenarios.

## Table of Contents

- [From Upstream rules_dotnet](#from-upstream-rules_dotnet)
- [From MSBuild (.csproj)](#from-msbuild-csproj)
- [From NuGet Package Managers](#from-nuget-package-managers)
- [From Visual Studio Projects](#from-visual-studio-projects)
- [VSTO Projects](#vsto-projects)
- [Common Migration Issues](#common-migration-issues)

---

## From Upstream rules_dotnet

If you're using the official [rules_dotnet](https://github.com/bazelbuild/rules_dotnet) and need .NET Framework support, you'll need to migrate to this fork.

### Why Migrate?

**Upstream rules_dotnet** (as of 2021+):
- Removed .NET Framework support
- Focuses on .NET Core 3.1 and .NET 5+
- Cross-platform (Windows, Linux, macOS)

**rules_dotnet_framework** (this fork):
- Based on d672bdb commit (January 2021, before Framework removal)
- .NET Framework 4.7-4.7.2 ONLY
- Windows-only
- Added VSTO and WiX support

### Migration Steps

#### 1. Update WORKSPACE

**Before (upstream rules_dotnet):**
```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_dotnet_framework",
    sha256 = "...",
    url = "https://github.com/bazelbuild/rules_dotnet/archive/...",
)

load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_register_toolchains", "dotnet_repositories")

dotnet_repositories()

dotnet_register_toolchains("dotnet", "3.1.100")  # .NET Core SDK
```

**After (rules_dotnet_framework):**
```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_dotnet_framework",
    sha256 = "...",
    url = "https://github.com/balzso/rules_dotnet_framework/archive/...",
)

load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_repositories")

dotnet_repositories()

load("@rules_dotnet_framework//dotnet:defs.bzl", "dotnet_repositories_nugets", "net_register_sdk", "dotnet_register_toolchains")

net_register_sdk()  # Auto-detect .NET Framework SDK

dotnet_register_toolchains()

dotnet_repositories_nugets()  # Test frameworks
```

#### 2. Update Build Rules

**Rule name changes:**

| Upstream | rules_dotnet_framework | Notes |
|----------|------------------------|-------|
| `core_library` | `net_library` | .NET Framework class library |
| `core_binary` | `net_binary` | .NET Framework executable |
| `core_resource` | `net_resource` | Embedded resources |
| `core_resx` | `net_resx` | .resx resource files |
| `core_import_library` | `net_import_library` | Import precompiled DLL |
| `core_nunit_test` | `net_nunit3_test` | NUnit 3 tests |
| `core_xunit_test` | `net_xunit_test` | xUnit tests |

**Before:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "core_library", "core_binary")

core_library(
    name = "MyLib.dll",
    srcs = ["MyClass.cs"],
    deps = ["@some_package//:core_lib"],
)

core_binary(
    name = "MyApp.exe",
    srcs = ["Program.cs"],
    deps = [":MyLib.dll"],
)
```

**After:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_library", "net_binary")

net_library(
    name = "MyLib.dll",
    srcs = ["MyClass.cs"],
    target_framework = "net472",  # Explicit target framework
    deps = ["@some_package//:net_lib"],  # Changed attribute name
)

net_binary(
    name = "MyApp.exe",
    srcs = ["Program.cs"],
    target_framework = "net472",
    deps = [":MyLib.dll"],
)
```

#### 3. Update NuGet Package References

NuGet package dependencies changed from `core_*` attributes to `net_*`:

**Before:**
```python
nuget_package(
    name = "newtonsoft.json",
    package = "Newtonsoft.Json",
    version = "12.0.3",
    core_lib = "lib/netstandard2.0/Newtonsoft.Json.dll",
    core_deps = [...],
)
```

**After:**
```python
nuget_package(
    name = "newtonsoft.json",
    package = "Newtonsoft.Json",
    version = "12.0.3",
    net_lib = "lib/net47/Newtonsoft.Json.dll",  # Framework-specific path
    net_deps = [...],
)
```

Use `nuget2bazel` tool to regenerate package definitions:

```bash
bazel build //tools/nuget2bazel:nuget2bazel.exe
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3
```

#### 4. Remove Cross-Platform Code

This fork is Windows-only. Remove any Mono or cross-platform specific code:

**Remove:**
- `mono_library`, `mono_binary` rules
- Platform-specific conditionals for macOS/Linux
- Mono SDK references

#### 5. Update Target Frameworks

Change from .NET Core TFMs to .NET Framework TFMs:

| .NET Core | .NET Framework |
|-----------|----------------|
| `netcoreapp3.1` | `net472` |
| `netstandard2.0` | `net471` |
| `netstandard2.1` | `net472` |

---

## From MSBuild (.csproj)

Migrating a traditional Visual Studio .csproj project to Bazel.

### Step-by-Step Migration

#### 1. Analyze Project Structure

Look at your `.csproj` file:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net472</TargetFramework>
    <OutputType>Library</OutputType>
    <AssemblyName>MyCompany.MyLibrary</AssemblyName>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="12.0.3" />
    <PackageReference Include="NLog" Version="4.7.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\OtherLib\OtherLib.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Compile Include="**\*.cs" />
    <EmbeddedResource Include="Resources\Strings.resx" />
  </ItemGroup>
</Project>
```

#### 2. Create BUILD.bazel

```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_library", "net_resx")

# Compile .resx to .resources
net_resx(
    name = "Strings",
    src = "Resources/Strings.resx",
    identifier = "MyCompany.MyLibrary.Resources.Strings.resources",
)

# Build library
net_library(
    name = "MyLibrary.dll",
    srcs = glob(["**/*.cs"]),
    resources = [":Strings"],
    target_framework = "net472",
    deps = [
        "//OtherLib:OtherLib.dll",  # ProjectReference
        "@newtonsoft.json//:net_lib",  # PackageReference
        "@nlog//:net_lib",  # PackageReference
    ],
    visibility = ["//visibility:public"],
)
```

#### 3. Add NuGet Packages

Use `nuget2bazel` tool:

```bash
# Build the tool
bazel build //tools/nuget2bazel:nuget2bazel.exe

# Add packages
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . NLog 4.7.0
```

This creates/updates `nuget.bzl` and WORKSPACE entries.

#### 4. Handle AssemblyInfo

If using `AssemblyInfo.cs`:

**Option A:** Keep existing `AssemblyInfo.cs`
```python
net_library(
    name = "MyLibrary.dll",
    srcs = glob(["**/*.cs"]),  # Includes AssemblyInfo.cs
    ...
)
```

**Option B:** Generate from BUILD file (future feature)
```python
# Not yet implemented - keep AssemblyInfo.cs for now
```

#### 5. Build and Test

```bash
# Build library
bazel build //path/to:MyLibrary.dll

# Output: bazel-bin/path/to/MyLibrary.dll
```

### Common .csproj to BUILD.bazel Mappings

| .csproj Element | BUILD.bazel Equivalent |
|----------------|------------------------|
| `<OutputType>Library</OutputType>` | `net_library()` |
| `<OutputType>Exe</OutputType>` | `net_binary()` |
| `<TargetFramework>net472</TargetFramework>` | `target_framework = "net472"` |
| `<PackageReference Include="X" />` | `deps = ["@x//:net_lib"]` |
| `<ProjectReference Include="Y.csproj" />` | `deps = ["//path/to:Y.dll"]` |
| `<Reference Include="Z.dll" />` | `deps = ["@z//:Z.dll"]` (via `net_import_library`) |
| `<Compile Include="A.cs" />` | `srcs = ["A.cs"]` or `glob(["**/*.cs"])` |
| `<EmbeddedResource Include="R.resx" />` | `net_resx()` + `resources = [...]` |
| `<Content Include="data.txt" />` | `data = ["data.txt"]` |

---

## From NuGet Package Managers

### packages.config

If using `packages.config`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Newtonsoft.Json" version="12.0.3" targetFramework="net472" />
  <package id="NLog" version="4.7.0" targetFramework="net472" />
</packages>
```

**Migration:**

1. Extract package names and versions from `packages.config`
2. Add each package using `nuget2bazel`:

```bash
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . NLog 4.7.0
```

3. Reference in BUILD.bazel:

```python
deps = [
    "@newtonsoft.json//:net_lib",
    "@nlog//:net_lib",
]
```

### PackageReference (SDK-style)

If using SDK-style projects with `<PackageReference>`:

```xml
<ItemGroup>
  <PackageReference Include="Newtonsoft.Json" Version="12.0.3" />
</ItemGroup>
```

Same process as `packages.config` above.

---

## From Visual Studio Projects

### Solution Structure

If you have a Visual Studio solution with multiple projects:

```
MySolution.sln
├── MyApp/
│   ├── MyApp.csproj
│   └── Program.cs
├── MyLib/
│   ├── MyLib.csproj
│   └── MyClass.cs
└── MyTests/
    ├── MyTests.csproj
    └── MyTests.cs
```

**Convert to Bazel:**

```
MySolution/
├── WORKSPACE
├── BUILD.bazel (optional root)
├── MyApp/
│   ├── BUILD.bazel
│   └── Program.cs
├── MyLib/
│   ├── BUILD.bazel
│   └── MyClass.cs
└── MyTests/
    ├── BUILD.bazel
    └── MyTests.cs
```

**MyLib/BUILD.bazel:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_library")

net_library(
    name = "MyLib.dll",
    srcs = ["MyClass.cs"],
    target_framework = "net472",
    visibility = ["//visibility:public"],
)
```

**MyApp/BUILD.bazel:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_binary")

net_binary(
    name = "MyApp.exe",
    srcs = ["Program.cs"],
    target_framework = "net472",
    deps = ["//MyLib:MyLib.dll"],
)
```

**MyTests/BUILD.bazel:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_nunit3_test")

net_nunit3_test(
    name = "MyTests.dll",
    srcs = ["MyTests.cs"],
    target_framework = "net472",
    deps = [
        "//MyLib:MyLib.dll",
        "@nunit//:net_lib",
    ],
)
```

### Debugging in Visual Studio

Bazel builds are separate from Visual Studio. To debug:

**Option 1:** Use bazel-built binaries
1. Build with Bazel: `bazel build //MyApp:MyApp.exe`
2. In Visual Studio: Debug > Attach to Process
3. Run: `bazel-bin\MyApp\MyApp.exe`
4. Attach debugger to running process

**Option 2:** Keep .csproj for debugging only
1. Keep `.csproj` files (don't check into Bazel builds)
2. Use for IDE intellisense and debugging
3. Use Bazel for production builds

---

## VSTO Projects

Migrating VSTO (Office add-in) projects from Visual Studio to Bazel.

### Traditional VSTO Project Structure

```
MyExcelAddIn/
├── MyExcelAddIn.csproj
├── ThisAddIn.cs
├── Ribbon1.cs
├── Ribbon1.Designer.cs
├── MyExcelAddIn.snk (strong name key)
└── Properties/
    └── AssemblyInfo.cs
```

### Bazel VSTO Project

```
MyExcelAddIn/
├── BUILD.bazel
├── ThisAddIn.cs
├── Ribbon1.cs
├── Ribbon1.Designer.cs
└── MyExcelAddIn.snk
```

**BUILD.bazel:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_vsto_addin")

net_vsto_addin(
    name = "MyExcelAddIn.dll",
    srcs = [
        "ThisAddIn.cs",
        "Ribbon1.cs",
        "Ribbon1.Designer.cs",
    ],
    office_app = "Excel",
    office_version = "2016",
    target_framework = "net472",
    keyfile = "MyExcelAddIn.snk",
)
```

### VSTO Installer (WiX)

**Before (Visual Studio):**
- .vdproj (Visual Studio Installer Project)
- InstallShield
- Advanced Installer

**After (Bazel with WiX):**

```
MyExcelAddIn/
├── BUILD.bazel (add-in)
└── Setup.Wix/
    ├── BUILD.bazel (installer)
    ├── Product.wxs
    ├── Files.wxs
    └── Registry.wxs
```

**Setup.Wix/BUILD.bazel:**
```python
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
    upgrade_code = "YOUR-UPGRADE-CODE-GUID-HERE",  # Generate once, never change!
    manufacturer = "My Company",
    product_name = "My Excel Add-in",
    extensions = ["WixToolset.UI.wixext"],
)
```

**Generate UpgradeCode:**
```powershell
[guid]::NewGuid()
```
Save this GUID - you'll need the same one for all future versions!

### Key Differences

| Visual Studio VSTO | rules_dotnet_framework |
|--------------------|------------------------|
| .csproj + .vdproj | BUILD.bazel (single source) |
| Manual PIA references | Automatic PIA handling |
| MSBuild publish | Bazel build |
| ClickOnce wizard | Automatic manifest generation |
| Manual signing | Integrated signing |

---

## Common Migration Issues

### Issue: "csc.exe not found"

**Cause:** .NET Framework SDK not detected.

**Solution:**
```python
# In WORKSPACE
net_register_sdk(
    dotnet_sdk = "C:/Program Files (x86)/Microsoft SDKs/Windows/v10.0A/bin/NETFX 4.7.2 Tools/",
)
```

Or install .NET Framework 4.7.2 Developer Pack.

### Issue: "Target must end with .dll or .exe"

**Cause:** Missing file extension in rule name.

**Before:**
```python
net_library(
    name = "MyLib",  # WRONG
    ...
)
```

**After:**
```python
net_library(
    name = "MyLib.dll",  # CORRECT
    ...
)
```

### Issue: NuGet package not found

**Cause:** Package not registered in WORKSPACE.

**Solution:**
```bash
bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . PackageName Version
```

This updates `nuget.bzl` and WORKSPACE automatically.

### Issue: "The type or namespace name could not be found"

**Cause:** Missing dependency or wrong target framework.

**Solutions:**

1. Check `deps` includes all required assemblies
2. Verify `target_framework` matches (e.g., `net472`)
3. For system assemblies, use `net_gac`:

```python
load("@rules_dotnet_framework//dotnet:defs.bzl", "net_gac")

net_gac(
    name = "system_web",
    assembly = "System.Web",
    version = "4.0.0.0",
)

net_library(
    name = "MyLib.dll",
    deps = [":system_web"],
    ...
)
```

### Issue: Long path errors on Windows

**Cause:** Bazel creates deep directory structures.

**Solution:**

1. Enable long paths in Windows 10+:
```powershell
reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1
```

2. Use shorter output_base:
```bash
bazel --output_base=C:\b build //...
```

3. Set TMP to short path:
```cmd
set TMP=C:\TEMP
set TEMP=C:\TEMP
```

### Issue: VSTO add-in not loading in Office

**Cause:** Registry keys or manifest issues.

**Checklist:**

1. Manifest signed with trusted certificate
2. Registry keys correctly set (HKCU\Software\Microsoft\Office\Excel\Addins\...)
3. LoadBehavior = 3
4. VSTO Runtime installed
5. .NET Framework 4.7+ installed
6. Trust center settings allow add-in

**Debug:**
```cmd
# Check registry
reg query HKCU\Software\Microsoft\Office\Excel\Addins

# Check VSTO log (set environment variable first)
set VSTO_LOGALERTS=1
set VSTO_SUPPRESSDISPLAYALERTS=0
```

### Issue: WiX build fails with "Component GUID conflicts"

**Cause:** Auto-generated GUIDs changing between builds.

**Solution:** Use explicit GUIDs in .wxs files:

```xml
<Component Id="MainDLL" Guid="91650F42-69E2-4DBC-8F83-C5EE73FC3E0E">
  <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
</Component>
```

Never change GUIDs once released!

---

## Migration Checklist

Use this checklist when migrating a project:

- [ ] Update WORKSPACE with `net_register_sdk()` and `dotnet_register_toolchains()`
- [ ] Create BUILD.bazel files for each project
- [ ] Change rule names from `core_*`/`mono_*` to `net_*`
- [ ] Add `.dll` or `.exe` extensions to all target names
- [ ] Set `target_framework = "net472"` (or net47/net471)
- [ ] Add NuGet packages using `nuget2bazel` tool
- [ ] Update dependency references (`deps` attribute)
- [ ] Convert `.resx` files using `net_resx()` rule
- [ ] Handle embedded resources with `resources` attribute
- [ ] Test build: `bazel build //...`
- [ ] Test run: `bazel run //path/to:MyApp.exe`
- [ ] Test clean build: `bazel clean && bazel build //...`
- [ ] For VSTO: Verify Office PIAs are included
- [ ] For VSTO: Test manifest generation and signing
- [ ] For installers: Create WiX .wxs files
- [ ] For installers: Generate and save UpgradeCode GUID
- [ ] Document any custom build steps in README

---

## Getting Help

- **Documentation:** See `docs/` directory for detailed guides
- **Examples:** See `tests/examples/` for working examples
- **Issues:** Check GitHub issues for known problems
- **Upstream:** For non-Framework issues, check [upstream rules_dotnet](https://github.com/bazelbuild/rules_dotnet)

**Key documentation:**
- `README.md` - Quick start
- `dotnet/core.rst` - Rule reference
- `dotnet/wix.rst` - WiX integration
- `docs/vsto.md` - VSTO development
- `CLAUDE.md` - Architecture and development guide
