"""Actions for generating ClickOnce application manifests for VSTO add-ins"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def emit_application_manifest(
        dotnet,
        name,
        assembly,
        deps = [],
        trust_level = "FullTrust",
        processor_architecture = "msil"):
    """Generates a ClickOnce application manifest (.dll.manifest) for a VSTO add-in.

    Args:
        dotnet: The dotnet context from dotnet_context()
        name: Name of the output manifest file (typically assembly_name + ".manifest")
        assembly: The compiled assembly File object
        deps: List of DotnetLibrary providers for dependencies
        trust_level: Security trust level (FullTrust or PartialTrust)
        processor_architecture: Target architecture (msil, x86, amd64)

    Returns:
        File object for the generated manifest
    """

    # Get mage.exe tool
    mage_tool = dotnet.mage
    mage_wrapper = dotnet.mage_wrapper

    # Output manifest file (temporary, will be post-processed)
    temp_manifest = dotnet.actions.declare_file(name + ".manifest.tmp")
    manifest = dotnet.actions.declare_file(name + ".manifest")

    # Build mage.exe arguments for creating application manifest
    #
    # mage.exe command line format:
    # mage.exe -New Application -ToFile <output.manifest> -FromDirectory <app_dir> \
    #          -Name "<name>" -Version <version> -TrustLevel <trust>
    #
    # For VSTO add-ins, we need:
    # -New Application: Create new application manifest
    # -ToFile: Output file
    # -Name: Application name
    # -Version: Assembly version
    # -TrustLevel: Security permissions (FullTrust for Office add-ins)
    # -Processor: Target architecture

    args = dotnet.actions.args()
    args.add(mage_tool.path)  # Path to mage.exe
    args.add("-New")
    args.add("Application")
    args.add("-ToFile")
    args.add(temp_manifest.path)  # Write to temp file first
    args.add("-Name")
    args.add(name)
    args.add("-Version")
    args.add("1.0.0.0")  # Default version, can be parameterized later
    args.add("-TrustLevel")
    args.add(trust_level)
    args.add("-Processor")
    args.add(processor_architecture)

    # Include the main assembly
    args.add("-FromDirectory")
    args.add(paths.dirname(assembly.path))

    # Execute mage_wrapper to generate the manifest
    dotnet.actions.run(
        executable = mage_wrapper,
        arguments = [args],
        inputs = [assembly, mage_tool],
        outputs = [temp_manifest],
        mnemonic = "DotnetApplicationManifest",
        progress_message = "Generating application manifest for {}".format(name),
    )

    # Post-process manifest to fix assembly identity
    # mage.exe generates: <assemblyIdentity name="DigitalRobotExcel.exe" ...
    # We need: <assemblyIdentity name="DigitalRobotExcel.dll" ...
    assembly_basename = paths.basename(assembly.path)  # e.g., "DigitalRobotExcel.dll"
    assembly_name_no_ext = assembly_basename.replace(".dll", "")  # e.g., "DigitalRobotExcel"

    fix_script = dotnet.actions.declare_file(name + "_fix_manifest.ps1")
    fix_script_content = """
$content = Get-Content '{}' -Raw -Encoding UTF8
$content = $content -replace 'name="{}.exe"', 'name="{}.dll"'
Set-Content '{}' -Value $content -Encoding UTF8 -NoNewline
""".format(
        temp_manifest.path.replace("/", "\\"),
        assembly_name_no_ext,
        assembly_name_no_ext,
        manifest.path.replace("/", "\\"),
    )

    dotnet.actions.write(
        output = fix_script,
        content = fix_script_content,
    )

    dotnet.actions.run(
        executable = "powershell.exe",
        arguments = ["-ExecutionPolicy", "Bypass", "-File", fix_script.path],
        inputs = [temp_manifest, fix_script],
        outputs = [manifest],
        mnemonic = "FixManifestAssemblyIdentity",
        progress_message = "Fixing application manifest assembly identity for {}".format(name),
    )

    return manifest
