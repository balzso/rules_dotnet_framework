CI Configuration
================

.. note::
   This documentation is adapted from the original `rules_dotnet <https://github.com/bazelbuild/rules_dotnet>`_ project (commit d672bdb).
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

This guide covers continuous integration setup for rules_dotnet_framework projects.
All builds must run on Windows agents/runners.

GitHub Actions Setup
--------------------

GitHub Actions is the recommended CI platform for modern projects.

**Example workflow** (``.github/workflows/build.yml``):

.. code:: yaml

    name: Build

    on:
      push:
        branches: [ main, master ]
      pull_request:
        branches: [ main, master ]

    jobs:
      build:
        runs-on: windows-latest

        steps:
        - uses: actions/checkout@v4

        - name: Setup Bazel
          uses: bazelbuild/setup-bazelisk@v2

        - name: Build
          run: bazel build //...

        - name: Test
          run: bazel test //... --test_output=errors

**With caching:**

.. code:: yaml

    - name: Cache Bazel
      uses: actions/cache@v3
      with:
        path: |
          ~/.cache/bazel
          C:\users\runneradmin\_bazel_runneradmin
        key: ${{ runner.os }}-bazel-${{ hashFiles('**/*.bzl', '**/*.bazel', 'WORKSPACE') }}
        restore-keys: |
          ${{ runner.os }}-bazel-

Prerequisites for Windows Runners
----------------------------------

GitHub-hosted ``windows-latest`` runners come pre-installed with:
- .NET Framework 4.7.2+ developer pack
- Windows SDK
- Visual Studio Build Tools

For self-hosted runners, ensure the following are installed:

**Required:**
- Windows 10+ (20H2 or later recommended)
- .NET Framework 4.7.2 Developer Pack
- Windows SDK (10.0.19041.0 or later)
- Bazel or Bazelisk

**Optional (for VSTO):**
- Visual Studio 2019/2022 with Office Developer Tools
- WiX Toolset v5 (``dotnet tool install --global wix``)

**Optional (for signing):**
- Authenticode certificate for code signing

Long Path Support
~~~~~~~~~~~~~~~~~

Enable long path support on Windows:

**Via Registry:**

.. code:: registry

    HKLM\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled = 1

**Via Group Policy:**

Computer Configuration → Administrative Templates → System → Filesystem → Enable Win32 long paths

**Via PowerShell (Admin):**

.. code:: powershell

    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                     -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

Azure DevOps Setup
------------------

For Azure DevOps pipelines:

**Example pipeline** (``azure-pipelines.yml``):

.. code:: yaml

    trigger:
    - main
    - master

    pool:
      vmImage: 'windows-latest'

    steps:
    - task: UseBazel@0
      inputs:
        version: 'latest'

    - script: bazel build //...
      displayName: 'Build all targets'

    - script: bazel test //... --test_output=errors
      displayName: 'Run tests'

    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: '**/bazel-testlogs/**/test.xml'
      condition: always()

Installing Dependencies
~~~~~~~~~~~~~~~~~~~~~~~

If using self-hosted Azure DevOps agents, install dependencies via Chocolatey:

.. code:: powershell

    # Install Chocolatey (if not already installed)
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    # Install .NET Framework developer packs
    choco install netfx-4.7.2-devpack -y

    # Install Bazel
    choco install bazel -y

    # Optional: WiX Toolset (via dotnet global tools)
    dotnet tool install --global wix

**Note:** Do NOT install Mono. This fork is Windows .NET Framework only.

Self-Hosted Build Agents
-------------------------

For self-hosted Windows build agents (GitHub Actions or Azure DevOps):

**Setup steps:**

1. **Install Windows 10+ (20H2 or later)**
   - Enable long path support (see above)
   - Enable Developer Mode (for symbolic links without admin)

2. **Install .NET Framework 4.7.2+ Developer Pack**

   Download: https://dotnet.microsoft.com/download/dotnet-framework/net472

3. **Install Windows SDK**

   Download: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

4. **Install Bazel or Bazelisk**

   Option A - Chocolatey:

   .. code:: bash

       choco install bazel

   Option B - Manual:

   Download from https://github.com/bazelbuild/bazel/releases

5. **Optional: Install Visual Studio 2019/2022**

   Required for VSTO development. Ensure "Office/SharePoint development" workload is installed.

6. **Configure environment variables:**

   .. code:: batch

       # Use short path for temp files (avoids long path issues with MSVC)
       setx TMP "C:\Temp" /M
       setx TEMP "C:\Temp" /M

7. **Create C:\Temp directory:**

   .. code:: batch

       mkdir C:\Temp

8. **Enable symbolic links without admin (optional):**

   Settings → Update & Security → For developers → Developer Mode = ON

Troubleshooting CI Builds
--------------------------

**"Path too long" errors:**

- Enable long path support (see above)
- Set TMP/TEMP to short paths
- Use ``--output_user_root=C:/b`` to shorten Bazel output paths

**"SDK not found" errors:**

- Verify .NET Framework 4.7.2 Developer Pack is installed
- Check Windows SDK is installed
- Ensure ``dotnet/private/sdk_net.bzl`` can find SDK paths

**"Permission denied" errors:**

- Run build agent as Administrator, or
- Enable Developer Mode for symbolic links, or
- Use ``--spawn_strategy=standalone`` to disable sandboxing

**Slow builds:**

- Use Bazel remote caching
- Enable ``--disk_cache`` for local caching
- Use GitHub Actions cache or Azure DevOps cache task

Example: Full GitHub Actions Workflow
--------------------------------------

Complete example with caching, VSTO support, and artifact publishing:

.. code:: yaml

    name: Build and Test

    on: [push, pull_request]

    jobs:
      build:
        runs-on: windows-latest

        steps:
        - uses: actions/checkout@v4

        - name: Setup Bazelisk
          uses: bazelbuild/setup-bazelisk@v2

        - name: Install WiX Toolset
          run: dotnet tool install --global wix

        - name: Cache Bazel
          uses: actions/cache@v3
          with:
            path: |
              ~/.cache/bazel
              C:\users\runneradmin\_bazel_runneradmin
            key: ${{ runner.os }}-bazel-${{ hashFiles('**/*.bzl', 'WORKSPACE') }}
            restore-keys: |
              ${{ runner.os }}-bazel-

        - name: Build all targets
          run: bazel build //...

        - name: Run tests
          run: bazel test //... --test_output=errors

        - name: Build release artifacts
          run: |
            bazel build //path/to:MyApp.exe --compilation_mode=opt
            bazel build //path/to/installer:MySetup.msi

        - name: Upload artifacts
          uses: actions/upload-artifact@v3
          with:
            name: release-binaries
            path: |
              bazel-bin/path/to/MyApp.exe
              bazel-bin/path/to/installer/MySetup.msi
