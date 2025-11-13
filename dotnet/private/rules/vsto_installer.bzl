"""High-level rule for building VSTO add-in installers"""

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)
load(
    "@io_bazel_rules_dotnet//dotnet/private/rules:wix_package.bzl",
    "wix_package",
)

def net_vsto_installer(
        name,
        vsto_addin,
        wxs_srcs,
        arch = "x86",
        product_version = "1.0.0",
        product_code = "*",
        upgrade_code = None,
        manufacturer = None,
        product_name = None,
        extensions = None,
        data = [],
        cert_file = None,
        cert_password = None,
        cert_thumbprint = None,
        timestamp_url = "http://timestamp.digicert.com",
        sign_description = None,
        **kwargs):
    """Builds a Windows Installer package for a VSTO add-in.

    This is a high-level convenience rule that wraps wix_package with
    VSTO-specific defaults and automatic configuration.

    Args:
        name: Name of the output MSI (must end with .msi)
        vsto_addin: Label of the net_vsto_addin target
        wxs_srcs: List of WiX source files (.wxs)
        arch: Target architecture (x86, x64, ARM64). Default: x86
        product_version: Product version (e.g., "1.0.0")
        product_code: Product GUID or "*" for auto-generation. Default: "*"
        upgrade_code: Upgrade code GUID (required for upgrades)
        manufacturer: Manufacturer name
        product_name: Product name (defaults to vsto_addin name)
        extensions: List of WiX extensions. Default: ["WixToolset.UI.wixext"]
        data: Additional data files (e.g., License.rtf, icons)
        cert_file: Optional PFX certificate file for signing
        cert_password: Optional certificate password
        cert_thumbprint: Optional certificate thumbprint
        timestamp_url: Timestamp server URL
        sign_description: Description for Authenticode signature
        **kwargs: Additional arguments passed to wix_package

    Example:
        net_vsto_installer(
            name = "MyExcelAddInSetup.msi",
            vsto_addin = ":MyExcelAddIn.dll",
            wxs_srcs = [
                "Product.wxs",
                "Files.wxs",
                "Registry.wxs",
                "UI.wxs",
            ],
            arch = "x86",
            product_version = "1.0.0",
            upgrade_code = "9B3C7D4B-82C9-403E-8F6C-FF77844CF4FF",
            manufacturer = "MyCompany",
            product_name = "My Excel Add-in",
            data = ["License.rtf"],
            cert_file = "certificate.pfx",
        )
    """

    # Validate inputs
    if not name.endswith(".msi"):
        fail("net_vsto_installer name must end with .msi: {}".format(name))

    if not upgrade_code:
        fail("net_vsto_installer requires upgrade_code for proper upgrade support")

    # Default extensions for VSTO installers
    if extensions == None:
        extensions = ["WixToolset.UI.wixext"]

    # Build WiX preprocessor defines
    defines = {
        "ProductVersion": product_version,
        "ProductCode": product_code,
        "UpgradeCode": upgrade_code,
    }

    if manufacturer:
        defines["Manufacturer"] = manufacturer

    if product_name:
        defines["ProductName"] = product_name

    # VSTO Utilities bindpath
    # This assumes vsto_utilities_register() has been called in WORKSPACE
    # The bindpath should point to the external repository
    bindpaths = {
        # Note: In WiX, bindpaths are used to locate files referenced in .wxs
        # The actual path will be resolved by the wix_build action
        # For now, we'll use a placeholder that will be replaced during build
        "VsReferenceAssemblies": "../vsto_utilities",
    }

    # Merge with any user-provided defines/bindpaths in kwargs
    if "defines" in kwargs:
        defines.update(kwargs.pop("defines"))

    if "bindpaths" in kwargs:
        bindpaths.update(kwargs.pop("bindpaths"))

    # Call wix_package with VSTO-specific configuration
    wix_package(
        name = name,
        srcs = wxs_srcs,
        vsto_addin = vsto_addin,
        data = data,
        arch = arch,
        defines = defines,
        bindpaths = bindpaths,
        extensions = extensions,
        cert_file = cert_file,
        cert_password = cert_password,
        cert_thumbprint = cert_thumbprint,
        timestamp_url = timestamp_url,
        sign_description = sign_description,
        **kwargs
    )
