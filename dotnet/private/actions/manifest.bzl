"""Actions for generating ClickOnce application manifests for VSTO add-ins"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def emit_application_manifest(
        dotnet,
        name,
        assembly,
        deps = [],
        version = "1.0.0.0",
        trust_level = "FullTrust",
        processor_architecture = "msil",
        entry_point_class = None,
        office_app = "Excel",
        friendly_name = None,
        ribbon_types = [],
        certificate_file = None,
        certificate_password = None):
    """Generates a ClickOnce application manifest (.dll.manifest) for a VSTO add-in.

    Directly generates the manifest XML to match VSTO structure, avoiding MSBuild
    GenerateApplicationManifest task limitations with DLL-based add-ins.

    Args:
        dotnet: The dotnet context from dotnet_context()
        name: Name of the output manifest file (typically assembly_name + ".manifest")
        assembly: The compiled assembly File object
        deps: List of DotnetLibrary providers for dependencies
        version: Assembly version string (e.g., "1.2.0.0")
        trust_level: Security trust level (FullTrust or PartialTrust)
        processor_architecture: Target architecture (msil, x86, amd64)
        entry_point_class: VSTO add-in entry point class (e.g., "MyAddin.ThisAddIn")
                          If None, defaults to "{name}.ThisAddIn"
        office_app: Office application name (e.g., "Excel", "Word", "Outlook")
        friendly_name: Display name for the add-in. If None, defaults to name
        ribbon_types: List of ribbon control class names (e.g., ["MyAddin.RibbonControl"])
                     Required for Excel ribbon UI to load
        certificate_file: PFX certificate file for Authenticode signing
                         If None, manifest is not signed
        certificate_password: Password for the PFX certificate file

    Returns:
        File object for the generated manifest
    """

    # Output manifest file (.dll.manifest for VSTO add-ins)
    # If signing, create unsigned temp file first; otherwise use final name
    if certificate_file:
        unsigned_manifest = dotnet.actions.declare_file(name + ".dll.manifest.unsigned")
        manifest = dotnet.actions.declare_file(name + ".dll.manifest")
    else:
        unsigned_manifest = dotnet.actions.declare_file(name + ".dll.manifest")
        manifest = unsigned_manifest

    assembly_basename = paths.basename(assembly.path)  # e.g., "DigitalRobotExcel.dll"
    assembly_name_no_ext = assembly_basename.replace(".dll", "")  # e.g., "DigitalRobotExcel"

    # Set defaults for VSTO-specific parameters
    if not entry_point_class:
        entry_point_class = "{}.ThisAddIn".format(assembly_name_no_ext)
    if not friendly_name:
        friendly_name = assembly_name_no_ext

    # Collect all dependency DLL files from deps
    # This includes transitive dependencies and their runfiles
    dependency_files = []
    seen_paths = {}  # Track seen files to avoid duplicates

    for dep in deps:
        # Add main result DLL from dependency
        if hasattr(dep, "result") and dep.result and dep.result.path.endswith(".dll"):
            dll_path = dep.result.path
            if dll_path not in seen_paths:
                dependency_files.append(dep.result)
                seen_paths[dll_path] = True

        # Add dependency runfiles (additional DLLs)
        if hasattr(dep, "runfiles"):
            for runfile in dep.runfiles.to_list():
                if runfile.path.endswith(".dll"):
                    dll_path = runfile.path
                    if dll_path not in seen_paths:
                        dependency_files.append(runfile)
                        seen_paths[dll_path] = True

    # Build dependency XML entries
    # VSTO manifests use dependentAssembly with dependencyType="preRequisite"
    dependency_xml = ""
    for dep_file in dependency_files:
        dep_basename = paths.basename(dep_file.path)
        dep_name = dep_basename.replace(".dll", "")
        # Escape XML special characters
        dep_name_xml = dep_name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        dependency_xml += """
  <dependency>
    <dependentAssembly dependencyType="preRequisite" allowDelayedBinding="true">
      <assemblyIdentity name="{name}" version="1.0.0.0" publicKeyToken="0000000000000000" language="neutral" processorArchitecture="msil" />
    </dependentAssembly>
  </dependency>""".format(name=dep_name_xml)

    # Build ribbonTypes XML entries
    # Required for Excel to load ribbon UI controls
    ribbon_types_xml = ""
    if ribbon_types:
        ribbon_types_xml = "\n            <vstov4.1:ribbonTypes xmlns:vstov4.1=\"urn:schemas-microsoft-com:vsto.v4.1\">"
        for ribbon_type in ribbon_types:
            # Format: "Namespace.ClassName, AssemblyName, Version=X.Y.Z.W, Culture=neutral, PublicKeyToken=null"
            ribbon_type_full = "{}, {}, Version={}, Culture=neutral, PublicKeyToken=null".format(
                ribbon_type,
                assembly_name_no_ext,
                version,
            )
            ribbon_types_xml += "\n              <vstov4.1:ribbonType name=\"{}\" />".format(ribbon_type_full)
        ribbon_types_xml += "\n            </vstov4.1:ribbonTypes>"

    # Generate VSTO manifest XML
    # Structure based on working VSTO manifest from C:\Temp\DigitalRobotExcel
    manifest_xml = """<?xml version="1.0" encoding="utf-8"?>
<asmv1:assembly xsi:schemaLocation="urn:schemas-microsoft-com:asm.v1 assembly.adaptive.xsd" manifestVersion="1.0" xmlns:asmv1="urn:schemas-microsoft-com:asm.v1" xmlns="urn:schemas-microsoft-com:asm.v2" xmlns:asmv2="urn:schemas-microsoft-com:asm.v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:co.v1="urn:schemas-microsoft-com:clickonce.v1" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" xmlns:co.v2="urn:schemas-microsoft-com:clickonce.v2">
  <asmv1:assemblyIdentity name="{assembly_name_with_ext}" version="{version}" publicKeyToken="0000000000000000" language="neutral" processorArchitecture="{processor}" type="win32" />
  <description xmlns="urn:schemas-microsoft-com:asm.v1">{description}</description>
  <application />
  <entryPoint>
    <co.v1:customHostSpecified />
  </entryPoint>
  <trustInfo>
    <security>
      <applicationRequestMinimum>
        <PermissionSet Unrestricted="true" ID="Custom" SameSite="site" />
        <defaultAssemblyRequest permissionSetReference="Custom" />
      </applicationRequestMinimum>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="asInvoker" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
  <dependency>
    <dependentOS>
      <osVersionInfo>
        <os majorVersion="5" minorVersion="1" buildNumber="2600" servicePackMajor="0" />
      </osVersionInfo>
    </dependentOS>
  </dependency>
  <dependency>
    <dependentAssembly dependencyType="preRequisite" allowDelayedBinding="true">
      <assemblyIdentity name="Microsoft.Windows.CommonLanguageRuntime" version="4.0.30319.0" />
    </dependentAssembly>
  </dependency>{dependency_xml}
  <file name="{assembly_basename}" size="{assembly_size}">
    <hash>
      <dsig:Transforms>
        <dsig:Transform Algorithm="urn:schemas-microsoft-com:HashTransforms.Identity" />
      </dsig:Transforms>
      <dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
      <dsig:DigestValue>AAAAAAAAAAAAAAAAAAAAAAAAAAA=</dsig:DigestValue>
    </hash>
  </file>
  <vstav3:addIn xmlns:vstav3="urn:schemas-microsoft-com:vsta.v3">
    <vstav3:entryPointsCollection>
      <vstav3:entryPoints>
        <vstav3:entryPoint class="{entry_point_class}">
          <assemblyIdentity name="{assembly_name_no_ext}" version="{version}" language="neutral" processorArchitecture="{processor}" />
        </vstav3:entryPoint>
      </vstav3:entryPoints>
    </vstav3:entryPointsCollection>
    <vstav3:update enabled="true">
      <vstav3:expiration maximumAge="7" unit="days" />
    </vstav3:update>
    <vstav3:application>
      <vstov4:customizations xmlns:vstov4="urn:schemas-microsoft-com:vsto.v4">
        <vstov4:customization>
          <vstov4:appAddIn application="{office_app}" loadBehavior="3" keyName="{assembly_name_no_ext}">
            <vstov4:friendlyName>{friendly_name}</vstov4:friendlyName>
            <vstov4:description>{description}</vstov4:description>{ribbon_types_xml}
          </vstov4:appAddIn>
        </vstov4:customization>
      </vstov4:customizations>
    </vstav3:application>
  </vstav3:addIn>
</asmv1:assembly>
""".format(
        assembly_name_with_ext = assembly_basename,
        assembly_name_no_ext = assembly_name_no_ext,
        version = version,
        processor = processor_architecture,
        description = assembly_name_no_ext,
        dependency_xml = dependency_xml,
        assembly_basename = assembly_basename,
        assembly_size = "0",  # Will be replaced by signing tool
        entry_point_class = entry_point_class,
        office_app = office_app,
        friendly_name = friendly_name,
        ribbon_types_xml = ribbon_types_xml,
    )

    # Write unsigned manifest XML
    dotnet.actions.write(
        output = unsigned_manifest,
        content = manifest_xml,
    )

    # Sign manifest if certificate file is provided
    if certificate_file:
        # Get mage.exe tool
        mage_tool = dotnet.mage
        mage_wrapper = dotnet.mage_wrapper

        # Create PowerShell script to sign and copy in one action
        # Script generates temp path in Windows TEMP to avoid Bazel sandbox permissions
        sign_script = dotnet.actions.declare_file(name + "_sign_manifest.ps1")
        sign_script_content = """
param($mageWrapper, $mageExe, $unsigned, $cert, $pwd, $final)

# Generate unique temp path (mage.exe creates files as ReadOnly)
$uniqueId = [guid]::NewGuid().ToString("N").Substring(0, 8)
$tempManifest = Join-Path $env:TEMP "mage_manifest_${{uniqueId}}.tmp"

# Copy unsigned manifest to temp location (Windows TEMP is always writable)
Copy-Item $unsigned $tempManifest -Force

# Remove ReadOnly attribute (mage.exe can only sign writable files)
$file = Get-Item $tempManifest
$file.IsReadOnly = $false

# Sign the manifest in-place (wrapper expects: mage_wrapper.exe mage.exe [args...])
$mageArgs = @($mageExe, '-Sign', $tempManifest, '-CertFile', $cert, '-Password', $pwd, '-ToFile', $tempManifest)
$process = Start-Process -FilePath $mageWrapper -ArgumentList $mageArgs -Wait -PassThru -NoNewWindow
$exitCode = $process.ExitCode

if ($exitCode -ne 0) {{
    Write-Error "mage.exe signing failed with exit code $exitCode"
    Remove-Item $tempManifest -Force -ErrorAction SilentlyContinue
    exit $exitCode
}}

# Verify signing succeeded
if (-not (Test-Path $tempManifest)) {{
    Write-Error "mage.exe did not create signed file at $tempManifest"
    exit 1
}}

# Copy signed manifest to final Bazel output
Copy-Item $tempManifest $final -Force

# Clean up temp file
Remove-Item $tempManifest -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $final)) {{
    Write-Error "Failed to copy signed manifest to $final"
    exit 1
}}
""".format()

        dotnet.actions.write(
            output = sign_script,
            content = sign_script_content,
        )

        # Execute signing script
        # PowerShell can write to Bazel outputs, and mage.exe writes to Windows TEMP
        dotnet.actions.run(
            executable = "powershell.exe",
            arguments = [
                "-ExecutionPolicy", "Bypass",
                "-File", sign_script.path,
                mage_wrapper.path,
                mage_tool.path,
                unsigned_manifest.path,
                certificate_file.path,
                certificate_password if certificate_password else "",
                manifest.path,
            ],
            inputs = [sign_script, unsigned_manifest, mage_wrapper, mage_tool, certificate_file],
            outputs = [manifest],
            mnemonic = "SignApplicationManifest",
            progress_message = "Signing application manifest for {}".format(name),
        )

    return manifest
