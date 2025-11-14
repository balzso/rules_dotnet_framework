"""WiX build action for creating Windows Installer packages"""

load("@rules_dotnet_skylib//lib:paths.bzl", "paths")

def emit_wix_package(
        ctx,
        name,
        wxs_srcs,
        staging_dir,
        arch = "x86",
        defines = {},
        bindpaths = {},
        extensions = [],
        cultures = [],
        output_name = None):
    """
    Builds a Windows Installer package (.msi) using WiX Toolset v5.

    Args:
        ctx: Rule context
        name: Name of the output MSI (without extension)
        wxs_srcs: List of .wxs source files
        staging_dir: Staging directory with VSTO files (from wix_stage action)
        arch: Target architecture (x86, x64, ARM64)
        defines: Dictionary of WiX preprocessor variables (e.g., {"ProductVersion": "1.0.0"})
        bindpaths: Dictionary of bindpath mappings (e.g., {"VsReferenceAssemblies": "/path"})
        extensions: List of WiX extension names (e.g., ["WixToolset.UI.wixext"])
        cultures: List of culture identifiers for localization (e.g., ["en-US"])
        output_name: Optional custom output filename (default: name + ".msi")

    Returns:
        File object for the generated MSI package
    """

    # Determine output filename
    if not output_name:
        output_name = name if name.endswith(".msi") else name + ".msi"

    # Declare output MSI file
    msi_output = ctx.actions.declare_file(output_name)

    # Get wix.exe tool from toolchain
    # Note: This assumes wix_toolchain is properly configured
    # For now, we'll use a simple approach with ctx.executable
    wix_exe = ctx.executable._wix_tool if hasattr(ctx.attr, "_wix_tool") else None

    if not wix_exe:
        fail("WiX tool not found. Ensure wix_toolchain is registered in WORKSPACE.")

    # Build wix.exe command line
    args = ctx.actions.args()

    # Command: wix build
    args.add("build")

    # Output file
    args.add("-out", msi_output.path)

    # Architecture
    args.add("-arch", arch)

    # Preprocessor defines
    # Add SourceDir pointing to staging directory
    args.add("-d", "SourceDir=" + staging_dir.path)

    for key, value in defines.items():
        args.add("-d", "{}={}".format(key, value))

    # Bindpaths
    for name_key, path_value in bindpaths.items():
        args.add("-bindpath", "{}={}".format(name_key, path_value))

    # Extensions
    for ext in extensions:
        args.add("-ext", ext)

    # Cultures
    for culture in cultures:
        args.add("-culture", culture)

    # WiX source files (.wxs)
    for wxs in wxs_srcs:
        args.add(wxs.path)

    # Collect all inputs
    inputs = list(wxs_srcs)
    inputs.append(staging_dir)

    # Execute wix build
    ctx.actions.run(
        executable = wix_exe,
        arguments = [args],
        inputs = inputs,
        outputs = [msi_output],
        mnemonic = "WixBuild",
        progress_message = "Building Windows Installer package: {}".format(output_name),
        execution_requirements = {
            # WiX may need access to file system for extensions
            "no-sandbox": "1",
        },
    )

    return msi_output

def emit_wix_package_with_wrapper(
        ctx,
        name,
        wxs_srcs,
        staging_dir,
        wix_wrapper,
        wix_tool,
        arch = "x86",
        defines = {},
        bindpaths = {},
        extensions = [],
        data_files = []):
    """
    Builds WiX package using a wrapper tool (similar to mage_wrapper pattern).

    This approach is more compatible with the existing toolchain pattern
    used for mage.exe and signtool.exe.

    Args:
        ctx: Rule context
        name: Output MSI name
        wxs_srcs: List of .wxs source files
        staging_dir: Staging directory
        wix_wrapper: Wrapper executable for wix.exe
        wix_tool: Actual wix.exe tool
        arch: Architecture
        defines: Preprocessor defines
        bindpaths: Bindpath mappings
        extensions: WiX extensions
        data_files: Additional data files (e.g., License.rtf)

    Returns:
        File object for MSI
    """

    # Output MSI
    output_name = name if name.endswith(".msi") else name + ".msi"
    msi_output = ctx.actions.declare_file(output_name)

    # Build arguments for wix_wrapper
    # Format: wix_wrapper <wix.exe path> build <args...>
    args = ctx.actions.args()

    # Path to wix.exe
    args.add(wix_tool.path)

    # wix build command
    args.add("build")
    args.add("-out", msi_output.path)
    args.add("-arch", arch)

    # Defines
    args.add("-d", "SourceDir=" + staging_dir.path)
    for key, value in defines.items():
        # Quote values that contain spaces
        if " " in value:
            args.add("-d", "{}=\"{}\"".format(key, value))
        else:
            args.add("-d", "{}={}".format(key, value))

    # Bindpaths
    for bind_name, bind_path in bindpaths.items():
        args.add("-bindpath", "{}={}".format(bind_name, bind_path))

    # Extensions
    for ext in extensions:
        args.add("-ext", ext)

    # Source files
    for wxs in wxs_srcs:
        args.add(wxs.path)

    # Inputs
    inputs = list(wxs_srcs) + data_files + [staging_dir, wix_tool]

    # Add VSTO Utilities if bindpath references them
    # Look for VsReferenceAssemblies in bindpaths
    if "VsReferenceAssemblies" in bindpaths:
        # Try to add VSTO utilities from the repository
        # Note: This requires the repository to be registered in WORKSPACE
        # The actual utilities files should be available via @vsto_utilities//:dlls
        pass  # For now, the bindpath will be passed directly to WiX

    # Execute via wrapper
    ctx.actions.run(
        executable = wix_wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = [msi_output],
        mnemonic = "WixBuild",
        progress_message = "Building Windows Installer: {}".format(output_name),
    )

    return msi_output
