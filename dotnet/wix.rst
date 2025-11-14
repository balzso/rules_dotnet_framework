WiX Toolset rules
==================

.. note::
   This documentation covers WiX Toolset v5 integration added in rules_dotnet_framework.
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

.. _wix: https://wixtoolset.org/
.. _wix_v5: https://wixtoolset.org/docs/intro/

.. role:: param(emphasis)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**

The WiX rules provide integration with WiX Toolset v5 for building Windows Installer packages (.msi).
These rules are specifically designed for creating installers for .NET Framework applications and VSTO add-ins.

.. contents:: :depth: 2

-----

Overview
--------

WiX (Windows Installer XML) is a toolset for building Windows installation packages from XML source code.
This ruleset integrates WiX Toolset v5 into Bazel, enabling reproducible installer builds.

**Key features:**

- Build .msi packages from .wxs source files
- Automatic file staging with proper directory structure
- Support for WiX extensions (WixToolset.UI.wixext, WixToolset.Util.wixext, etc.)
- Authenticode signing for installers
- VSTO-specific installer support with automatic VSTO Utilities bundling
- Pure Bazel workflow (no MSBuild or .wixproj files required)

**Requirements:**

- WiX Toolset v5 installed via ``dotnet tool install --global wix``
- Visual Studio with Office Developer Tools (for VSTO installers)
- Windows SDK (for signtool.exe)

API
---

wix_package
~~~~~~~~~~~

Generic rule for building Windows Installer packages from WiX source files.

**Attributes:**

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`name`                  | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| A unique name for this target. Must end with ``.msi``                                           |
+--------------------------------+-----------------------------------------------------------------+
| :param:`wxs_srcs`              | :type:`label_list`                                              |
+--------------------------------+-----------------------------------------------------------------+
| |mandatory| List of WiX source files (.wxs). These define the installer structure,            |
| components, features, and UI.                                                                   |
+--------------------------------+-----------------------------------------------------------------+
| :param:`data`                  | :type:`label_list`                                              |
+--------------------------------+-----------------------------------------------------------------+
| Additional files to stage for the installer (e.g., License.rtf, images, etc.)                  |
+--------------------------------+-----------------------------------------------------------------+
| :param:`deps`                  | :type:`label_list`                                              |
+--------------------------------+-----------------------------------------------------------------+
| .NET assemblies and other files to include in the installer. These are automatically           |
| staged in the appropriate directory structure.                                                  |
+--------------------------------+-----------------------------------------------------------------+
| :param:`arch`                  | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Target architecture: ``x86``, ``x64``, or ``arm64``. Default: ``x86``                          |
+--------------------------------+-----------------------------------------------------------------+
| :param:`product_version`       | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Product version in X.Y.Z format (e.g., "1.0.0"). Used for upgrade detection.                   |
+--------------------------------+-----------------------------------------------------------------+
| :param:`upgrade_code`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| **CRITICAL:** Product upgrade GUID. Must remain constant across all versions to enable         |
| upgrades. Never change this value once released!                                                |
+--------------------------------+-----------------------------------------------------------------+
| :param:`manufacturer`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Manufacturer/company name displayed in installer and Add/Remove Programs.                       |
+--------------------------------+-----------------------------------------------------------------+
| :param:`product_name`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Product name displayed in installer and Add/Remove Programs.                                    |
+--------------------------------+-----------------------------------------------------------------+
| :param:`extensions`            | :type:`string_list`                                             |
+--------------------------------+-----------------------------------------------------------------+
| WiX extensions to load (e.g., ``["WixToolset.UI.wixext", "WixToolset.Util.wixext"]``)          |
+--------------------------------+-----------------------------------------------------------------+
| :param:`defines`               | :type:`string_dict`                                             |
+--------------------------------+-----------------------------------------------------------------+
| Preprocessor defines passed to WiX compiler. Format: ``{"VAR": "value"}``                       |
+--------------------------------+-----------------------------------------------------------------+
| :param:`bindpaths`             | :type:`string_dict`                                             |
+--------------------------------+-----------------------------------------------------------------+
| Additional bindpaths for WiX linker. Format: ``{"name": "path"}``                               |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_file`             | :type:`label`                                                   |
+--------------------------------+-----------------------------------------------------------------+
| Authenticode certificate file (.pfx) for signing the .msi package.                              |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_password`         | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Password for the certificate file. Warning: Consider using cert_thumbprint instead.             |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_thumbprint`       | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Certificate thumbprint for signing from Windows certificate store.                              |
+--------------------------------+-----------------------------------------------------------------+
| :param:`timestamp_url`         | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Timestamp server URL for Authenticode signing. Default: ``http://timestamp.digicert.com``       |
+--------------------------------+-----------------------------------------------------------------+

**Example:**

.. code:: python

  load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "wix_package", "net_library")

  net_library(
      name = "MyApp.dll",
      srcs = ["Program.cs", "Helper.cs"],
      target_framework = "net472",
  )

  wix_package(
      name = "MyAppSetup.msi",
      wxs_srcs = [
          "Product.wxs",
          "Files.wxs",
          "Registry.wxs",
      ],
      data = [
          "License.rtf",
          "Banner.bmp",
          "Dialog.bmp",
      ],
      deps = [":MyApp.dll"],
      arch = "x64",
      product_version = "1.0.0",
      upgrade_code = "12345678-1234-1234-1234-123456789ABC",  # NEVER CHANGE!
      manufacturer = "My Company",
      product_name = "My Application",
      extensions = ["WixToolset.UI.wixext"],
      cert_file = "//certs:codesign.pfx",
      timestamp_url = "http://timestamp.digicert.com",
  )

net_vsto_installer
~~~~~~~~~~~~~~~~~~

High-level rule for building Windows Installer packages specifically for VSTO add-ins.
This rule automatically handles VSTO-specific requirements like bundling VSTO Utilities.

**Attributes:**

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`name`                  | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| A unique name for this target. Must end with ``.msi``                                           |
+--------------------------------+-----------------------------------------------------------------+
| :param:`vsto_addin`            | :type:`label`                                                   |
+--------------------------------+-----------------------------------------------------------------+
| |mandatory| The VSTO add-in target to package (must be a ``net_vsto_addin`` target).           |
+--------------------------------+-----------------------------------------------------------------+
| :param:`wxs_srcs`              | :type:`label_list`                                              |
+--------------------------------+-----------------------------------------------------------------+
| |mandatory| List of WiX source files (.wxs). Should include components for installing          |
| the VSTO add-in and registry keys.                                                              |
+--------------------------------+-----------------------------------------------------------------+
| :param:`data`                  | :type:`label_list`                                              |
+--------------------------------+-----------------------------------------------------------------+
| Additional files to stage for the installer (e.g., License.rtf, images, etc.)                  |
+--------------------------------+-----------------------------------------------------------------+
| :param:`arch`                  | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Target architecture: ``x86`` or ``x64``. **For VSTO add-ins, use x86 for maximum               |
| compatibility.** Default: ``x86``                                                               |
+--------------------------------+-----------------------------------------------------------------+
| :param:`product_version`       | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Product version in X.Y.Z format (e.g., "1.0.0"). Used for upgrade detection.                   |
+--------------------------------+-----------------------------------------------------------------+
| :param:`upgrade_code`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| **CRITICAL:** Product upgrade GUID. Must remain constant across all versions to enable         |
| upgrades. Never change this value once released!                                                |
+--------------------------------+-----------------------------------------------------------------+
| :param:`manufacturer`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Manufacturer/company name displayed in installer and Add/Remove Programs.                       |
+--------------------------------+-----------------------------------------------------------------+
| :param:`product_name`          | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Product name displayed in installer and Add/Remove Programs.                                    |
+--------------------------------+-----------------------------------------------------------------+
| :param:`extensions`            | :type:`string_list`                                             |
+--------------------------------+-----------------------------------------------------------------+
| WiX extensions to load. Common for VSTO: ``["WixToolset.UI.wixext"]``                          |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_file`             | :type:`label`                                                   |
+--------------------------------+-----------------------------------------------------------------+
| Authenticode certificate file (.pfx) for signing the .msi package. **Highly recommended         |
| for VSTO installers.**                                                                          |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_password`         | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Password for the certificate file.                                                              |
+--------------------------------+-----------------------------------------------------------------+
| :param:`cert_thumbprint`       | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| Certificate thumbprint for signing from Windows certificate store.                              |
+--------------------------------+-----------------------------------------------------------------+

**Example:**

.. code:: python

  load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_vsto_addin", "net_vsto_installer")

  net_vsto_addin(
      name = "MyExcelAddIn.dll",
      srcs = [
          "ThisAddIn.cs",
          "Ribbon1.cs",
          "TaskPane.cs",
      ],
      office_app = "Excel",
      office_version = "2016",
      target_framework = "net472",
      keyfile = "MyAddIn.snk",
  )

  net_vsto_installer(
      name = "MyExcelAddInSetup.msi",
      vsto_addin = ":MyExcelAddIn.dll",
      wxs_srcs = [
          "Product.wxs",
          "Files.wxs",
          "Registry.wxs",
      ],
      data = [
          "License.rtf",
      ],
      arch = "x86",  # Recommended for Office add-ins
      product_version = "1.0.0",
      upgrade_code = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF",  # NEVER CHANGE!
      manufacturer = "My Company",
      product_name = "My Excel Add-in",
      extensions = ["WixToolset.UI.wixext"],
      cert_file = "//certs:codesign.pfx",
  )

-----

WiX Source Files
----------------

WiX source files (.wxs) use standard WiX v5 XML syntax. The build system automatically provides
certain preprocessor variables and bindpaths.

Automatic Variables
~~~~~~~~~~~~~~~~~~~

**$(var.SourceDir)**
  Points to the staging directory where all files are prepared. Use this to reference files
  in your WiX source:

  .. code:: xml

    <File Id="MyApp.dll" Source="$(var.SourceDir)\MyApp.dll" KeyPath="yes" />

**VsReferenceAssemblies bindpath**
  For VSTO installers, automatically configured to point to VSTO Utilities location:

  .. code:: xml

    <File Source="!(bindpath.VsReferenceAssemblies)\Microsoft.Office.Tools.Common.v4.0.Utilities.dll" />

Directory Structure
~~~~~~~~~~~~~~~~~~~

Files are staged in a structure similar to MSBuild output:

::

  staging/
  ├── MyApp.dll                    # Main assembly
  ├── MyApp.dll.manifest           # Application manifest (VSTO)
  ├── MyApp.vsto                   # Deployment manifest (VSTO)
  ├── MyDependency.dll             # Dependencies
  └── License.rtf                  # Data files

Component GUIDs
~~~~~~~~~~~~~~~

**CRITICAL: Component GUID stability**

For proper Windows Installer upgrade functionality, component GUIDs must remain stable across versions.

**Best practices:**

1. **Main application DLL**: Use explicit GUID (never auto-generate)

   .. code:: xml

     <Component Id="MainDLL" Guid="91650F42-69E2-4DBC-8F83-C5EE73FC3E0E">
       <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
     </Component>

2. **VSTO manifests**: Use explicit GUIDs

   .. code:: xml

     <Component Id="ApplicationManifest" Guid="A1B2C3D4-E5F6-7890-ABCD-EF1234567890">
       <File Id="MyAddIn.dll.manifest" Source="$(var.SourceDir)\MyAddIn.dll.manifest" />
     </Component>

     <Component Id="DeploymentManifest" Guid="B2C3D4E5-F6A7-8901-BCDE-F12345678901">
       <File Id="MyAddIn.vsto" Source="$(var.SourceDir)\MyAddIn.vsto" />
     </Component>

3. **Registry keys**: Always use explicit GUIDs

   .. code:: xml

     <Component Id="RegistryEntries" Guid="C3D4E5F6-A7B8-9012-CDEF-123456789012">
       <RegistryKey Root="HKCU" Key="Software\Microsoft\Office\Excel\Addins\MyAddIn">
         <RegistryValue Name="Manifest" Value="[INSTALLFOLDER]MyAddIn.vsto" Type="string" />
       </RegistryKey>
     </Component>

Example WiX Files
~~~~~~~~~~~~~~~~~

**Product.wxs** (Main installer definition):

.. code:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
    <Package Name="My Excel Add-in"
             Manufacturer="My Company"
             Version="1.0.0"
             UpgradeCode="9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF">

      <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />

      <MediaTemplate EmbedCab="yes" />

      <Feature Id="ProductFeature" Title="My Excel Add-in" Level="1">
        <ComponentGroupRef Id="ProductComponents" />
        <ComponentGroupRef Id="RegistryComponents" />
      </Feature>
    </Package>
  </Wix>

**Files.wxs** (Component definitions):

.. code:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
    <Fragment>
      <StandardDirectory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="MyExcelAddIn" />
      </StandardDirectory>
    </Fragment>

    <Fragment>
      <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
        <Component Id="MainDLL" Guid="91650F42-69E2-4DBC-8F83-C5EE73FC3E0E">
          <File Id="MyAddIn.dll" Source="$(var.SourceDir)\MyAddIn.dll" KeyPath="yes" />
        </Component>

        <Component Id="ApplicationManifest" Guid="A1B2C3D4-E5F6-7890-ABCD-EF1234567890">
          <File Id="MyAddIn.dll.manifest" Source="$(var.SourceDir)\MyAddIn.dll.manifest" />
        </Component>

        <Component Id="DeploymentManifest" Guid="B2C3D4E5-F6A7-8901-BCDE-F12345678901">
          <File Id="MyAddIn.vsto" Source="$(var.SourceDir)\MyAddIn.vsto" />
        </Component>

        <!-- VSTO Utilities -->
        <Component Id="VSTOUtils" Guid="D3E4F5A6-B7C8-9012-DEFG-234567890123">
          <File Source="!(bindpath.VsReferenceAssemblies)\Microsoft.Office.Tools.Common.v4.0.Utilities.dll" />
        </Component>
      </ComponentGroup>
    </Fragment>
  </Wix>

**Registry.wxs** (VSTO registry keys):

.. code:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
    <Fragment>
      <ComponentGroup Id="RegistryComponents">
        <Component Id="RegistryEntries" Guid="C3D4E5F6-A7B8-9012-CDEF-123456789012" Directory="INSTALLFOLDER">
          <RegistryKey Root="HKCU" Key="Software\Microsoft\Office\Excel\Addins\MyCompany.MyExcelAddIn">
            <RegistryValue Name="Description" Value="My Excel Add-in" Type="string" />
            <RegistryValue Name="FriendlyName" Value="My Excel Add-in" Type="string" />
            <RegistryValue Name="LoadBehavior" Value="3" Type="integer" />
            <RegistryValue Name="Manifest" Value="[INSTALLFOLDER]MyAddIn.vsto|vstolocal" Type="string" />
          </RegistryKey>
        </Component>
      </ComponentGroup>
    </Fragment>
  </Wix>

-----

WiX Extensions
--------------

Common WiX extensions for .NET Framework installers:

**WixToolset.UI.wixext**
  Provides standard installer UI dialogs (Welcome, License, Install, Finish).

  .. code:: python

    extensions = ["WixToolset.UI.wixext"]

  In .wxs file:

  .. code:: xml

    <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
         xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui">
      <Package>
        <ui:WixUI Id="WixUI_Minimal" />
        <WixVariable Id="WixUILicenseRtf" Value="License.rtf" />
      </Package>
    </Wix>

**WixToolset.Util.wixext**
  Utilities for custom actions, registry operations, and service control.

  .. code:: python

    extensions = ["WixToolset.Util.wixext"]

**WixToolset.Netfx.wixext**
  .NET Framework detection and prerequisites.

  .. code:: python

    extensions = ["WixToolset.Netfx.wixext"]

  Example:

  .. code:: xml

    <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
         xmlns:netfx="http://wixtoolset.org/schemas/v4/wxs/netfx">
      <Package>
        <netfx:DotNetCoreSearch RuntimeType="aspnet"
                                Platform="x86"
                                MajorVersion="4"
                                Variable="NETFRAMEWORK472" />
      </Package>
    </Wix>

-----

Authenticode Signing
--------------------

Code signing is **highly recommended** for production installers, especially VSTO add-ins.

Certificate File
~~~~~~~~~~~~~~~~

Use a .pfx file with ``cert_file`` and ``cert_password``:

.. code:: python

  net_vsto_installer(
      name = "MyAddInSetup.msi",
      vsto_addin = ":MyAddIn.dll",
      wxs_srcs = ["Product.wxs"],
      cert_file = "//certs:codesign.pfx",
      cert_password = "MyPassword",  # Consider using cert_thumbprint instead
  )

Certificate Store
~~~~~~~~~~~~~~~~~

For better security, install certificate in Windows certificate store and use thumbprint:

.. code:: python

  net_vsto_installer(
      name = "MyAddInSetup.msi",
      vsto_addin = ":MyAddIn.dll",
      wxs_srcs = ["Product.wxs"],
      cert_thumbprint = "1234567890ABCDEF1234567890ABCDEF12345678",
  )

Timestamp Server
~~~~~~~~~~~~~~~~

Always use a timestamp server for code signing:

.. code:: python

  net_vsto_installer(
      name = "MyAddInSetup.msi",
      vsto_addin = ":MyAddIn.dll",
      wxs_srcs = ["Product.wxs"],
      cert_file = "//certs:codesign.pfx",
      timestamp_url = "http://timestamp.digicert.com",  # Default
  )

This ensures the signature remains valid even after the certificate expires.

-----

Troubleshooting
---------------

WiX Toolset Not Found
~~~~~~~~~~~~~~~~~~~~~~

Error: ``wix.exe not found``

**Solution:**

1. Install WiX Toolset v5:

   .. code:: bash

     dotnet tool install --global wix

2. Or specify explicit path in WORKSPACE:

   .. code:: python

     wix_register_sdk(
         wix_path = "C:/Users/Username/.dotnet/tools/wix.exe",
     )

VSTO Utilities Not Found
~~~~~~~~~~~~~~~~~~~~~~~~~

Error: ``Microsoft.Office.Tools.*.Utilities.dll not found``

**Solution:**

1. Install Visual Studio with Office Developer Tools workload

2. Or specify explicit path in WORKSPACE:

   .. code:: python

     vsto_utilities_register(
         vs_version = "2022",
         vs_edition = "Professional",
     )

Long Path Issues
~~~~~~~~~~~~~~~~

Error: ``The filename or extension is too long``

**Solution:**

1. Enable long path support in Windows:

   .. code:: bash

     reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1

2. Use shorter output_base for Bazel:

   .. code:: bash

     bazel build --output_base=C:/b //path/to:target.msi

Component GUID Conflicts
~~~~~~~~~~~~~~~~~~~~~~~~~

Error: ``Duplicate symbol 'Component:...'``

**Solution:**

Use explicit GUIDs for all components instead of auto-generation. Never change GUIDs once released.

Upgrade Not Working
~~~~~~~~~~~~~~~~~~~

**Symptoms:**
- Side-by-side installations instead of upgrade
- "Another version is already installed" error

**Solution:**

1. Verify ``upgrade_code`` has not changed
2. Check ``product_version`` is higher than previous release
3. Ensure main component GUIDs are identical across versions
4. Verify ``MajorUpgrade`` element is present in Product.wxs

-----

Best Practices
--------------

1. **GUID Management**
   - Never change UpgradeCode
   - Use explicit GUIDs for all components
   - Document all GUIDs in version control

2. **Versioning**
   - Use semantic versioning (X.Y.Z)
   - Increment version for every release
   - Windows Installer only uses first 3 numbers

3. **File Staging**
   - Let Bazel handle file staging automatically
   - Use $(var.SourceDir) in .wxs files
   - Don't hardcode absolute paths

4. **Code Signing**
   - Always sign production installers
   - Use timestamp server
   - Consider using certificate store instead of .pfx files

5. **Testing**
   - Test clean installation
   - Test upgrade from previous version
   - Test repair and uninstall
   - Test on clean Windows VMs

6. **VSTO Specific**
   - Use x86 architecture for maximum compatibility
   - Include VSTO Utilities in installer
   - Set proper registry keys for Office add-in
   - Sign both .msi and VSTO manifests

-----

See Also
--------

- :doc:`core` - Core .NET Framework rules
- :doc:`/docs/vsto` - VSTO add-in development guide
- :doc:`/docs/wix` - Detailed WiX integration guide
- `WiX Toolset Documentation <https://wixtoolset.org/docs/>`_
- `Visual Studio Tools for Office <https://docs.microsoft.com/en-us/visualstudio/vsto/>`_
