"""Actions for generating ClickOnce deployment manifests (.vsto) for VSTO add-ins"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def emit_deployment_manifest(
        dotnet,
        name,
        assembly,
        application_manifest,
        install_url = None,
        update_enabled = True,
        publisher_name = None,
        certificate_file = None,
        certificate_password = None):
    """Generates a ClickOnce deployment manifest (.vsto) for a VSTO add-in.

    Args:
        dotnet: The dotnet context from dotnet_context()
        name: Name of the output manifest file (typically assembly_name + ".vsto")
        assembly: The compiled assembly File object
        application_manifest: The application manifest File object
        install_url: Optional installation URL for network deployment
        update_enabled: Whether automatic updates are enabled
        publisher_name: Optional publisher name for the add-in
        certificate_file: PFX certificate file for Authenticode signing
                         If None, manifest is not signed
        certificate_password: Password for the PFX certificate file

    Returns:
        File object for the generated .vsto deployment manifest
    """

    # Get mage.exe tool
    mage_tool = dotnet.mage
    mage_wrapper = dotnet.mage_wrapper

    # Output .vsto file
    # If signing, create unsigned temp file; otherwise use final name
    if certificate_file:
        unsigned_vsto = dotnet.actions.declare_file(name + ".vsto.unsigned")
        vsto_manifest = dotnet.actions.declare_file(name + ".vsto")
    else:
        unsigned_vsto = dotnet.actions.declare_file(name + ".vsto")
        vsto_manifest = unsigned_vsto

    # Build mage.exe arguments for creating deployment manifest
    #
    # mage.exe command line format:
    # mage.exe -New Deployment -ToFile <output.vsto> -Name "<name>" \
    #          -Version <version> -AppManifest <app.manifest> \
    #          [-Install true|false] [-ProviderUrl <url>]
    #
    # For VSTO add-ins:
    # -New Deployment: Create new deployment manifest
    # -ToFile: Output .vsto file
    # -Name: Add-in name
    # -Version: Version number
    # -AppManifest: Reference to application manifest
    # -Install: Whether to install to Start Menu
    # -ProviderUrl: Update location URL

    # Generate temporary .vsto file (mage.exe creates incorrect codebase paths)
    temp_vsto = dotnet.actions.declare_file(name + ".vsto.tmp")

    args = dotnet.actions.args()
    args.add(mage_tool.path)  # Path to mage.exe
    args.add("-New")
    args.add("Deployment")
    args.add("-ToFile")
    args.add(temp_vsto.path)  # Write to temp file first
    args.add("-Name")
    args.add(name)
    args.add("-Version")
    args.add("1.0.0.0")  # Default version
    args.add("-AppManifest")
    args.add(application_manifest.path)

    # VSTO add-ins are typically not "installed" in the ClickOnce sense
    # They're registered via registry entries
    args.add("-Install")
    args.add("false")

    # Add install URL if provided
    if install_url:
        args.add("-ProviderUrl")
        args.add(install_url)

    # Execute mage_wrapper to generate the .vsto manifest
    dotnet.actions.run(
        executable = mage_wrapper,
        arguments = [args],
        inputs = [application_manifest, mage_tool],
        outputs = [temp_vsto],
        mnemonic = "DotnetDeploymentManifest",
        progress_message = "Generating deployment manifest (.vsto) for {}".format(name),
    )

    # Post-process .vsto to fix codebase path
    # manifest.bzl now generates files with .dll.manifest extension already
    # So we just use the basename as-is (no replacement needed)
    manifest_basename = paths.basename(application_manifest.path)
    manifest_basename_with_dll = manifest_basename  # Already has .dll.manifest extension

    fix_script = dotnet.actions.declare_file(name + "_fix_vsto.ps1")
    fix_script_content = """
$content = Get-Content '{}' -Raw -Encoding UTF8
$content = $content -replace 'codebase="/[^"]*"', 'codebase="{}"'
Set-Content '{}' -Value $content -Encoding UTF8 -NoNewline
""".format(temp_vsto.path.replace("/", "\\"), manifest_basename_with_dll, unsigned_vsto.path.replace("/", "\\"))

    dotnet.actions.write(
        output = fix_script,
        content = fix_script_content,
    )

    dotnet.actions.run(
        executable = "powershell.exe",
        arguments = ["-ExecutionPolicy", "Bypass", "-File", fix_script.path],
        inputs = [temp_vsto, fix_script],
        outputs = [unsigned_vsto],
        mnemonic = "FixVstoCodebase",
        progress_message = "Fixing .vsto codebase path for {}".format(name),
    )

    # Sign manifest if certificate file is provided
    if certificate_file:
        # Create PowerShell script to sign and copy in one action
        # Script generates temp path in Windows TEMP to avoid Bazel sandbox permissions
        sign_script = dotnet.actions.declare_file(name + "_sign_vsto.ps1")
        sign_script_content = """
param($mageWrapper, $mageExe, $unsigned, $cert, $pwd, $final)

# Generate unique temp path (mage.exe creates files as ReadOnly)
$uniqueId = [guid]::NewGuid().ToString("N").Substring(0, 8)
$tempManifest = Join-Path $env:TEMP "mage_vsto_${{uniqueId}}.tmp"

# Copy unsigned .vsto to temp location (Windows TEMP is always writable)
Copy-Item $unsigned $tempManifest -Force

# Remove ReadOnly attribute (mage.exe can only sign writable files)
$file = Get-Item $tempManifest
$file.IsReadOnly = $false

# Sign the .vsto manifest in-place (wrapper expects: mage_wrapper.exe mage.exe [args...])
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
    Write-Error "mage.exe did not create signed .vsto file at $tempManifest"
    exit 1
}}

# Copy signed .vsto to final Bazel output
Copy-Item $tempManifest $final -Force

# Clean up temp file
Remove-Item $tempManifest -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $final)) {{
    Write-Error "Failed to copy signed .vsto to $final"
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
                unsigned_vsto.path,
                certificate_file.path,
                certificate_password if certificate_password else "",
                vsto_manifest.path,
            ],
            inputs = [sign_script, unsigned_vsto, mage_wrapper, mage_tool, certificate_file],
            outputs = [vsto_manifest],
            mnemonic = "SignDeploymentManifest",
            progress_message = "Signing deployment manifest for {}".format(name),
        )

    return vsto_manifest
