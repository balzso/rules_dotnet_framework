"""Actions for generating ClickOnce deployment manifests (.vsto) for VSTO add-ins"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def emit_deployment_manifest(
        dotnet,
        name,
        assembly,
        application_manifest,
        install_url = None,
        update_enabled = True,
        publisher_name = None):
    """Generates a ClickOnce deployment manifest (.vsto) for a VSTO add-in.

    Args:
        dotnet: The dotnet context from dotnet_context()
        name: Name of the output manifest file (typically assembly_name + ".vsto")
        assembly: The compiled assembly File object
        application_manifest: The application manifest File object
        install_url: Optional installation URL for network deployment
        update_enabled: Whether automatic updates are enabled
        publisher_name: Optional publisher name for the add-in

    Returns:
        File object for the generated .vsto deployment manifest
    """

    # Get mage.exe tool
    mage_tool = dotnet.mage
    mage_wrapper = dotnet.mage_wrapper

    # Output .vsto file
    vsto_manifest = dotnet.actions.declare_file(name + ".vsto")

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
    # mage.exe generates: codebase="/DigitalRobotExcel.manifest"
    # We need: codebase="DigitalRobotExcel.dll.manifest"
    manifest_basename = paths.basename(application_manifest.path)
    manifest_basename_with_dll = manifest_basename.replace(".manifest", ".dll.manifest")

    fix_script = dotnet.actions.declare_file(name + "_fix_vsto.ps1")
    fix_script_content = """
$content = Get-Content '{}' -Raw -Encoding UTF8
$content = $content -replace 'codebase="/[^"]*"', 'codebase="{}"'
Set-Content '{}' -Value $content -Encoding UTF8 -NoNewline
""".format(temp_vsto.path.replace("/", "\\"), manifest_basename_with_dll, vsto_manifest.path.replace("/", "\\"))

    dotnet.actions.write(
        output = fix_script,
        content = fix_script_content,
    )

    dotnet.actions.run(
        executable = "powershell.exe",
        arguments = ["-ExecutionPolicy", "Bypass", "-File", fix_script.path],
        inputs = [temp_vsto, fix_script],
        outputs = [vsto_manifest],
        mnemonic = "FixVstoCodebase",
        progress_message = "Fixing .vsto codebase path for {}".format(name),
    )

    return vsto_manifest
