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

    # Output manifest file
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
    args.add(manifest.path)
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
        outputs = [manifest],
        mnemonic = "DotnetApplicationManifest",
        progress_message = "Generating application manifest for {}".format(name),
    )

    return manifest
