.. rules_dotnet_framework documentation master file

Welcome to rules_dotnet_framework's documentation!
===================================================

**rules_dotnet_framework** is a Bazel ruleset for building .NET Framework projects on Windows.

This is a fork of the original rules_dotnet, focused exclusively on .NET Framework 4.7-4.7.2 support.

Key features:
- .NET Framework 4.7, 4.7.1, 4.7.2 support
- Windows-only (no Mono, no cross-platform)
- VSTO (Visual Studio Tools for Office) add-in development
- WiX Toolset v5 integration for Windows Installer (.msi) packages
- NuGet package management

.. toctree::
   :maxdepth: 3
   :caption: Contents:

   CHANGELOG
   dotnet/core
   dotnet/wix
   dotnet/workspace
   dotnet/providers
   dotnet/toolchains
   docs/vsto
   docs/wix
   docs/runtime
   docs/multiversion
   docs/ci
   tests/README
   tests/examples/README
   tools/nuget2bazel/README

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
