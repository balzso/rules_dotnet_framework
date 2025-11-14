rules_dotnet_framework Fork (2024)
-----------------------------------

**This is a fork of rules_dotnet focused exclusively on .NET Framework 4.7-4.7.2 support.**

Fork created from upstream commit d672bdb (January 2021).

**Key differences from upstream:**

  - .NET Framework ONLY (no .NET Core, no .NET 5+)
  - Windows ONLY (no Mono, no cross-platform support)
  - Supports net47, net471, net472 only
  - **NEW:** VSTO (Visual Studio Tools for Office) add-in development support
  - **NEW:** WiX Toolset v5 integration for building Windows Installer (.msi) packages
  - Removed all .NET Core and Mono functionality
  - Updated documentation for Framework-only usage

**For .NET Core/5+ projects, use the official rules_dotnet instead:**
https://github.com/bazelbuild/rules_dotnet

-----

Release 1.0.0 (2024)
--------------------

Initial fork release with the following features:

New features:

  - VSTO add-in development support (net_vsto_addin rule)
  - Office PIA (Primary Interop Assembly) integration
  - ClickOnce manifest generation for VSTO deployments
  - Authenticode signing support for VSTO manifests and assemblies
  - WiX Toolset v5 integration (wix_package, net_vsto_installer rules)
  - Auto-detection of Visual Studio VSTO Utilities
  - Comprehensive VSTO and WiX documentation

Framework support:

  - .NET Framework 4.7 (net47)
  - .NET Framework 4.7.1 (net471)
  - .NET Framework 4.7.2 (net472)

Removed features:

  - All .NET Core support
  - All Mono support
  - Cross-platform builds (Windows-only)
  - .NET Framework versions below 4.7

-----

**Upstream Changelog (pre-fork history)**

Release 0.0.5 (2020-04-03)
--------------------------

Incompatible changes:

  - dotnet_repositories is move to @rules_dotnet_framework//dotnet:deps.bzl
    because it has to be called before loading any other rules_dotnet files.
  - dotnet_repositories_nugets() is added @rules_dotnet_framework//dotnet:defs.bzl.
    It registers all nuget packages used by test rules.

Important changes:

  - Extension names .dll, .exe are now required when defining rules_dotnet targets
    to improve compatibility with all frameworks.
  - netcoreapp3.1 support added.
  - Continuous integration jobs (travis-ci, appveyor and azure-pipelines) are fixed.

This release contains contributions from Pierre Lule, tomaszstrejczek and tomdegoede.

