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
        certificate_password = None,
        manifest_template_file = None):
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
        manifest_template_file: Optional MSBuild-generated manifest template file.
                               If provided, this template is used as a base instead of
                               generating a minimal manifest with mage.exe. This ensures
                               all dependencies (including GAC assemblies) are properly listed.

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
    # EXCLUDE: GAC assemblies from stdlib.net (mscorlib, System.*, etc.)
    # EXCLUDE: .NET Framework facade assemblies (type forwarders that cause VSTO LoadBehavior=2)

    # List of facade assembly names to exclude (these cause ClickOnce manifest validation failures)
    facade_assemblies = [
        "Microsoft.Vbe.Interop.dll", "Microsoft.Win32.Primitives.dll",
        "System.AppContext.dll", "System.Collections.dll", "System.Collections.Concurrent.dll",
        "System.Collections.NonGeneric.dll", "System.Collections.Specialized.dll",
        "System.ComponentModel.dll", "System.ComponentModel.Annotations.dll",
        "System.ComponentModel.EventBasedAsync.dll", "System.ComponentModel.Primitives.dll",
        "System.ComponentModel.TypeConverter.dll", "System.Console.dll", "System.Data.Common.dll",
        "System.Diagnostics.Contracts.dll", "System.Diagnostics.Debug.dll",
        "System.Diagnostics.FileVersionInfo.dll", "System.Diagnostics.Process.dll",
        "System.Diagnostics.StackTrace.dll", "System.Diagnostics.TextWriterTraceListener.dll",
        "System.Diagnostics.Tools.dll", "System.Diagnostics.TraceSource.dll",
        "System.Drawing.Primitives.dll", "System.Dynamic.Runtime.dll",
        "System.Globalization.dll", "System.Globalization.Calendars.dll",
        "System.Globalization.Extensions.dll", "System.IO.dll", "System.IO.Compression.ZipFile.dll",
        "System.IO.FileSystem.dll", "System.IO.FileSystem.DriveInfo.dll",
        "System.IO.FileSystem.Primitives.dll", "System.IO.FileSystem.Watcher.dll",
        "System.IO.IsolatedStorage.dll", "System.IO.MemoryMappedFiles.dll",
        "System.IO.Pipes.dll", "System.IO.UnmanagedMemoryStream.dll",
        "System.Linq.dll", "System.Linq.Expressions.dll", "System.Linq.Parallel.dll",
        "System.Linq.Queryable.dll", "System.Net.Http.Rtc.dll", "System.Net.NameResolution.dll",
        "System.Net.NetworkInformation.dll", "System.Net.Ping.dll", "System.Net.Primitives.dll",
        "System.Net.Requests.dll", "System.Net.Security.dll", "System.Net.Sockets.dll",
        "System.Net.WebHeaderCollection.dll", "System.Net.WebSockets.dll",
        "System.Net.WebSockets.Client.dll", "System.ObjectModel.dll", "System.Reflection.dll",
        "System.Reflection.Emit.dll", "System.Reflection.Emit.ILGeneration.dll",
        "System.Reflection.Emit.Lightweight.dll", "System.Reflection.Extensions.dll",
        "System.Reflection.Primitives.dll", "System.Resources.Reader.dll",
        "System.Resources.ResourceManager.dll", "System.Resources.Writer.dll",
        "System.Runtime.dll", "System.Runtime.CompilerServices.VisualC.dll",
        "System.Runtime.Extensions.dll", "System.Runtime.Handles.dll",
        "System.Runtime.InteropServices.dll", "System.Runtime.InteropServices.RuntimeInformation.dll",
        "System.Runtime.InteropServices.WindowsRuntime.dll", "System.Runtime.Numerics.dll",
        "System.Runtime.Serialization.Formatters.dll", "System.Runtime.Serialization.Json.dll",
        "System.Runtime.Serialization.Primitives.dll", "System.Runtime.Serialization.Xml.dll",
        "System.Security.Claims.dll", "System.Security.Cryptography.Algorithms.dll",
        "System.Security.Cryptography.Csp.dll", "System.Security.Cryptography.Encoding.dll",
        "System.Security.Cryptography.Primitives.dll", "System.Security.Cryptography.X509Certificates.dll",
        "System.Security.Principal.dll", "System.Security.SecureString.dll",
        "System.ServiceModel.Duplex.dll", "System.ServiceModel.Http.dll",
        "System.ServiceModel.NetTcp.dll", "System.ServiceModel.Primitives.dll",
        "System.ServiceModel.Security.dll", "System.Text.Encoding.dll",
        "System.Text.Encoding.Extensions.dll", "System.Text.RegularExpressions.dll",
        "System.Threading.dll", "System.Threading.Overlapped.dll", "System.Threading.Tasks.dll",
        "System.Threading.Tasks.Parallel.dll", "System.Threading.Thread.dll",
        "System.Threading.ThreadPool.dll", "System.Threading.Timer.dll",
        "System.ValueTuple.dll", "System.Xml.ReaderWriter.dll", "System.Xml.XDocument.dll",
        "System.Xml.XmlDocument.dll", "System.Xml.XmlSerializer.dll",
        "System.Xml.XPath.dll", "System.Xml.XPath.XDocument.dll",
    ]

    dependency_files = []
    seen_paths = {}  # Track seen files to avoid duplicates

    for dep in deps:
        # Add main result DLL from dependency
        if hasattr(dep, "result") and dep.result and dep.result.path.endswith(".dll"):
            dll_path = dep.result.path
            dll_basename = dll_path.split("/")[-1].split("\\")[-1]  # Get filename from path

            # Skip GAC assemblies (from stdlib.net) and facade assemblies (by name)
            if "stdlib.net" not in dll_path and dll_basename not in facade_assemblies and dll_path not in seen_paths:
                dependency_files.append(dep.result)
                seen_paths[dll_path] = True

        # Add dependency runfiles (additional DLLs)
        if hasattr(dep, "runfiles"):
            for runfile in dep.runfiles.to_list():
                if runfile.path.endswith(".dll"):
                    dll_path = runfile.path
                    dll_basename = dll_path.split("/")[-1].split("\\")[-1]  # Get filename from path

                    # Skip GAC assemblies (from stdlib.net) and facade assemblies (by name)
                    if "stdlib.net" not in dll_path and dll_basename not in facade_assemblies and dll_path not in seen_paths:
                        dependency_files.append(runfile)
                        seen_paths[dll_path] = True

    # Build ribbonTypes XML entries for VSTO customization
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

    # Get mage.exe tool (needed for dependency metadata reading)
    mage_tool = dotnet.mage
    mage_wrapper = dotnet.mage_wrapper

    # NEW APPROACH: Use MSBuild-generated manifest as template
    # This ensures we get all GAC dependencies (VSTO runtime, .NET Framework, etc.)
    # which mage.exe -FromDirectory cannot detect
    #
    # Strategy:
    # 1. Copy MSBuild manifest from bin/Release/AssemblyName.dll.manifest (if exists)
    # 2. Use mage.exe to update with current DLLs from staging directory
    # 3. Update VSTO-specific sections (version, ribbonTypes, etc.)

    # Build list of all DLL files to stage (main assembly + dependencies)
    all_dlls = [assembly] + dependency_files
    dll_paths_param = ";".join([dll.path for dll in all_dlls])

    generate_script = dotnet.actions.declare_file(name + "_generate_manifest.ps1")
    generate_script_content = """
param($mageWrapper, $mageExe, $dllPaths, $outputManifest, $assemblyName, $version, $processor, $entryPoint, $officeApp, $friendlyName, $ribbonTypesXml, $templatePath)

# Check for manifest template (priority order):
# 1. Explicit template file provided via Bazel attribute (recommended)
# 2. MSBuild-generated manifest in bin/Release/ (legacy fallback)
# 3. Generate minimal manifest with mage.exe (last resort)

$templateExists = $false
$templateSource = ""

if ($templatePath -and (Test-Path $templatePath)) {{
    # Priority 1: Use explicit template from Bazel attribute
    $msbuildManifest = $templatePath
    $templateExists = $true
    $templateSource = "Bazel manifest_template attribute"
    Write-Host "Using manifest template from: $templatePath"
}} else {{
    # Priority 2: Try MSBuild-generated manifest (legacy behavior)
    $msbuildManifest = "bin/Release/${{assemblyName}}.dll.manifest"
    if (Test-Path $msbuildManifest) {{
        $templateExists = $true
        $templateSource = "bin/Release/ directory"
        Write-Host "Using manifest template from: $msbuildManifest"
    }}
}}

if (-not $templateExists) {{
    Write-Warning "No manifest template found."
    Write-Warning "Generating minimal manifest with mage.exe. For full dependency list:"
    Write-Warning "  Option 1: Add manifest_template attribute to net_vsto_addin rule (recommended)"
    Write-Warning "  Option 2: Run 'msbuild /t:Build /p:Configuration=Release' before Bazel build"
}}

# Create staging directory in Windows TEMP
$uniqueId = [guid]::NewGuid().ToString("N").Substring(0, 8)
$stagingDir = Join-Path $env:TEMP "mage_staging_${{uniqueId}}"
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

try {{
    # Copy all DLL files to staging directory
    $dllArray = $dllPaths -split ';'
    foreach ($dll in $dllArray) {{
        if (Test-Path $dll) {{
            $dllName = Split-Path -Leaf $dll
            Copy-Item $dll (Join-Path $stagingDir $dllName) -Force
        }}
    }}

    # Remove GAC assemblies from staging directory before mage.exe processes them
    # These are .NET Framework base libraries that should NOT be deployed with the app
    $gacAssemblies = @(
        'mscorlib.dll', 'System.dll', 'System.Core.dll', 'System.Data.dll',
        'System.Drawing.dll', 'System.Web.dll', 'System.Windows.Forms.dll',
        'System.Xml.dll', 'System.Xml.Linq.dll', 'System.Net.Http.dll',
        'System.Numerics.dll', 'System.Runtime.Serialization.dll',
        'Microsoft.CSharp.dll', 'Microsoft.VisualBasic.dll',
        'Microsoft.Build.Framework.dll', 'Microsoft.Build.Tasks.v4.0.dll',
        'Microsoft.Build.Utilities.v4.0.dll', 'Microsoft.JScript.dll',
        'System.Configuration.Install.dll', 'System.ComponentModel.DataAnnotations.dll',
        'System.Data.SqlXml.dll', 'System.Deployment.dll', 'System.DirectoryServices.dll',
        'System.DirectoryServices.Protocols.dll', 'System.Dynamic.dll',
        'System.EnterpriseServices.dll', 'System.Management.dll',
        'System.Runtime.Caching.dll', 'System.Runtime.Serialization.Formatters.Soap.dll',
        'System.Security.dll', 'System.ServiceProcess.dll',
        'System.Web.ApplicationServices.dll', 'System.Web.RegularExpressions.dll',
        'System.Web.Services.dll', 'System.Xaml.dll',
        'Accessibility.dll', 'PresentationCore.dll', 'PresentationFramework.dll',
        'WindowsBase.dll', 'WindowsFormsIntegration.dll'
    )
    foreach ($gacDll in $gacAssemblies) {{
        $gacPath = Join-Path $stagingDir $gacDll
        if (Test-Path $gacPath) {{
            Remove-Item $gacPath -Force
        }}
    }}

    # Remove .NET Framework facade assemblies (type forwarders)
    # These are small DLLs from the Reference Assemblies that redirect to main GAC assemblies
    # We keep only the legitimate NuGet package DLLs and application DLLs
    # Using explicit list (same as dependency collection filter) to ensure consistency
    $facadeAssemblies = @(
        'Microsoft.Vbe.Interop.dll', 'Microsoft.Win32.Primitives.dll',
        'System.AppContext.dll', 'System.Collections.dll', 'System.Collections.Concurrent.dll',
        'System.Collections.NonGeneric.dll', 'System.Collections.Specialized.dll',
        'System.ComponentModel.dll', 'System.ComponentModel.Annotations.dll',
        'System.ComponentModel.EventBasedAsync.dll', 'System.ComponentModel.Primitives.dll',
        'System.ComponentModel.TypeConverter.dll', 'System.Console.dll', 'System.Data.Common.dll',
        'System.Diagnostics.Contracts.dll', 'System.Diagnostics.Debug.dll',
        'System.Diagnostics.FileVersionInfo.dll', 'System.Diagnostics.Process.dll',
        'System.Diagnostics.StackTrace.dll', 'System.Diagnostics.TextWriterTraceListener.dll',
        'System.Diagnostics.Tools.dll', 'System.Diagnostics.TraceSource.dll',
        'System.Diagnostics.Tracing.dll', 'System.Drawing.Primitives.dll',
        'System.Dynamic.Runtime.dll', 'System.Globalization.dll',
        'System.Globalization.Calendars.dll', 'System.Globalization.Extensions.dll',
        'System.IO.dll', 'System.IO.Compression.dll', 'System.IO.Compression.ZipFile.dll',
        'System.IO.FileSystem.dll', 'System.IO.FileSystem.DriveInfo.dll',
        'System.IO.FileSystem.Primitives.dll', 'System.IO.FileSystem.Watcher.dll',
        'System.IO.IsolatedStorage.dll', 'System.IO.MemoryMappedFiles.dll',
        'System.IO.Pipes.dll', 'System.IO.UnmanagedMemoryStream.dll',
        'System.Linq.dll', 'System.Linq.Expressions.dll', 'System.Linq.Parallel.dll',
        'System.Linq.Queryable.dll', 'System.Net.Http.dll', 'System.Net.NameResolution.dll',
        'System.Net.NetworkInformation.dll', 'System.Net.Ping.dll', 'System.Net.Primitives.dll',
        'System.Net.Requests.dll', 'System.Net.Security.dll', 'System.Net.Sockets.dll',
        'System.Net.WebHeaderCollection.dll', 'System.Net.WebSockets.Client.dll',
        'System.Net.WebSockets.dll', 'System.ObjectModel.dll', 'System.Reflection.dll',
        'System.Reflection.Extensions.dll', 'System.Reflection.Primitives.dll',
        'System.Resources.Reader.dll', 'System.Resources.ResourceManager.dll',
        'System.Resources.Writer.dll', 'System.Runtime.dll',
        'System.Runtime.CompilerServices.VisualC.dll', 'System.Runtime.Extensions.dll',
        'System.Runtime.Handles.dll', 'System.Runtime.InteropServices.dll',
        'System.Runtime.InteropServices.RuntimeInformation.dll', 'System.Runtime.Numerics.dll',
        'System.Runtime.Serialization.Formatters.dll', 'System.Runtime.Serialization.Json.dll',
        'System.Runtime.Serialization.Primitives.dll', 'System.Runtime.Serialization.Xml.dll',
        'System.Security.Claims.dll', 'System.Security.Cryptography.Algorithms.dll',
        'System.Security.Cryptography.Csp.dll', 'System.Security.Cryptography.Encoding.dll',
        'System.Security.Cryptography.Primitives.dll', 'System.Security.Cryptography.X509Certificates.dll',
        'System.Security.Principal.dll', 'System.Security.SecureString.dll',
        'System.ServiceModel.Duplex.dll', 'System.ServiceModel.Http.dll',
        'System.ServiceModel.NetTcp.dll', 'System.ServiceModel.Primitives.dll',
        'System.ServiceModel.Security.dll', 'System.Text.Encoding.dll',
        'System.Text.Encoding.Extensions.dll', 'System.Text.RegularExpressions.dll',
        'System.Threading.dll', 'System.Threading.Overlapped.dll', 'System.Threading.Tasks.dll',
        'System.Threading.Tasks.Parallel.dll', 'System.Threading.Thread.dll',
        'System.Threading.ThreadPool.dll', 'System.Threading.Timer.dll',
        'System.ValueTuple.dll', 'System.Xml.ReaderWriter.dll', 'System.Xml.XDocument.dll',
        'System.Xml.XmlDocument.dll', 'System.Xml.XmlSerializer.dll',
        'System.Xml.XPath.dll', 'System.Xml.XPath.XDocument.dll'
    )

    Get-ChildItem -Path $stagingDir -Filter '*.dll' -ErrorAction SilentlyContinue | Where-Object {{
        $_.Name -in $facadeAssemblies
    }} | ForEach-Object {{
        Remove-Item $_.FullName -Force
    }}

    if ($templateExists) {{
        # Use MSBuild manifest as template (copy to staging dir)
        $tempManifest = Join-Path $stagingDir "temp.manifest"
        Copy-Item $msbuildManifest $tempManifest -Force

        # NOTE: We don't run mage.exe -Update because it would fail trying to find GAC assemblies
        # The MSBuild manifest already has all the correct dependency metadata
        # We'll just update the version and VSTO sections below
    }} else {{
        # Fallback: Generate minimal manifest with mage.exe
        $tempManifest = Join-Path $stagingDir "temp.manifest"
        $mageArgs = @($mageExe, '-New', 'Application', '-FromDirectory', $stagingDir, '-ToFile', $tempManifest, '-Version', $version, '-Processor', $processor)
        $process = Start-Process -FilePath $mageWrapper -ArgumentList $mageArgs -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -ne 0) {{
            Write-Error "mage.exe -New failed with exit code $($process.ExitCode)"
            exit $process.ExitCode
        }}
    }}

    if (-not (Test-Path $tempManifest)) {{
        Write-Error "Manifest file not created at $tempManifest"
        exit 1
    }}

    # Read manifest XML
    [xml]$manifest = Get-Content $tempManifest

    # Update assemblyIdentity with current version
    $manifest.assembly.assemblyIdentity.version = $version
    $manifest.assembly.assemblyIdentity.name = "${{assemblyName}}.dll"

    # Remove existing vstav3:addIn element if present (from template)
    $vstoNs = "urn:schemas-microsoft-com:vsta.v3"
    $nsmgr = New-Object Xml.XmlNamespaceManager($manifest.NameTable)
    $nsmgr.AddNamespace("vstav3", $vstoNs)
    $existingAddIn = $manifest.assembly.SelectSingleNode("//vstav3:addIn", $nsmgr)
    if ($existingAddIn) {{
        $manifest.assembly.RemoveChild($existingAddIn) | Out-Null
    }}

    # Create new VSTO addIn element
    $vsto4Ns = "urn:schemas-microsoft-com:vsto.v4"
    $addInElement = $manifest.CreateElement("vstav3", "addIn", $vstoNs)

    # entryPointsCollection
    $entryPointsCollection = $manifest.CreateElement("vstav3", "entryPointsCollection", $vstoNs)
    $entryPoints = $manifest.CreateElement("vstav3", "entryPoints", $vstoNs)
    $entryPointElem = $manifest.CreateElement("vstav3", "entryPoint", $vstoNs)
    $entryPointElem.SetAttribute("class", $entryPoint)

    $assemblyIdentity = $manifest.CreateElement("assemblyIdentity", "urn:schemas-microsoft-com:asm.v2")
    $assemblyIdentity.SetAttribute("name", $assemblyName)
    $assemblyIdentity.SetAttribute("version", $version)
    $assemblyIdentity.SetAttribute("language", "neutral")
    $assemblyIdentity.SetAttribute("processorArchitecture", $processor)

    $entryPointElem.AppendChild($assemblyIdentity) | Out-Null
    $entryPoints.AppendChild($entryPointElem) | Out-Null
    $entryPointsCollection.AppendChild($entryPoints) | Out-Null
    $addInElement.AppendChild($entryPointsCollection) | Out-Null

    # update element
    $update = $manifest.CreateElement("vstav3", "update", $vstoNs)
    $update.SetAttribute("enabled", "true")
    $expiration = $manifest.CreateElement("vstav3", "expiration", $vstoNs)
    $expiration.SetAttribute("maximumAge", "7")
    $expiration.SetAttribute("unit", "days")
    $update.AppendChild($expiration) | Out-Null
    $addInElement.AppendChild($update) | Out-Null

    # application/customizations element
    $application = $manifest.CreateElement("vstav3", "application", $vstoNs)
    $customizations = $manifest.CreateElement("vstov4", "customizations", $vsto4Ns)
    $customization = $manifest.CreateElement("vstov4", "customization", $vsto4Ns)
    $appAddIn = $manifest.CreateElement("vstov4", "appAddIn", $vsto4Ns)
    $appAddIn.SetAttribute("application", $officeApp)
    $appAddIn.SetAttribute("loadBehavior", "3")
    $appAddIn.SetAttribute("keyName", $assemblyName)

    $friendlyNameElem = $manifest.CreateElement("vstov4", "friendlyName", $vsto4Ns)
    $friendlyNameElem.InnerText = $friendlyName
    $appAddIn.AppendChild($friendlyNameElem) | Out-Null

    $descriptionElem = $manifest.CreateElement("vstov4", "description", $vsto4Ns)
    $descriptionElem.InnerText = $assemblyName
    $appAddIn.AppendChild($descriptionElem) | Out-Null

    # Add ribbonTypes if provided
    if ($ribbonTypesXml) {{
        # Parse ribbon types XML fragment and append
        $ribbonFragment = [xml]("<root xmlns:vstov4.1='urn:schemas-microsoft-com:vsto.v4.1'>$ribbonTypesXml</root>")
        $importedNode = $manifest.ImportNode($ribbonFragment.root.ribbonTypes, $true)
        $appAddIn.AppendChild($importedNode) | Out-Null
    }}

    $customization.AppendChild($appAddIn) | Out-Null
    $customizations.AppendChild($customization) | Out-Null
    $application.AppendChild($customizations) | Out-Null
    $addInElement.AppendChild($application) | Out-Null

    # Append VSTO addIn to root assembly element
    $manifest.assembly.AppendChild($addInElement) | Out-Null

    # Save modified manifest to output
    $manifest.Save($outputManifest)

    if (-not (Test-Path $outputManifest)) {{
        Write-Error "Failed to save manifest to $outputManifest"
        exit 1
    }}
}} finally {{
    # Clean up staging directory
    if (Test-Path $stagingDir) {{
        Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }}
}}
""".format()

    dotnet.actions.write(
        output = generate_script,
        content = generate_script_content,
    )

    # Build inputs list (include template file if provided)
    script_inputs = [generate_script, mage_wrapper, mage_tool] + all_dlls
    if manifest_template_file:
        script_inputs.append(manifest_template_file)

    # Execute manifest generation script
    dotnet.actions.run(
        executable = "powershell.exe",
        arguments = [
            "-ExecutionPolicy", "Bypass",
            "-File", generate_script.path,
            mage_wrapper.path,
            mage_tool.path,
            dll_paths_param,
            unsigned_manifest.path,
            assembly_name_no_ext,
            version,
            processor_architecture,
            entry_point_class,
            office_app,
            friendly_name,
            ribbon_types_xml,
            manifest_template_file.path if manifest_template_file else "",
        ],
        inputs = script_inputs,
        outputs = [unsigned_manifest],
        mnemonic = "GenerateApplicationManifest",
        progress_message = "Generating application manifest for {}".format(name),
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
# Use SHA256RSA algorithm (SHA1 is deprecated and may be rejected by Office/VSTO runtime)
$mageArgs = @($mageExe, '-Sign', $tempManifest, '-CertFile', $cert, '-Password', $pwd, '-Algorithm', 'sha256RSA', '-ToFile', $tempManifest)
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
