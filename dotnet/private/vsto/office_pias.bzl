"""Office Primary Interop Assemblies (PIA) helpers"""

# Office PIA NuGet package references
# These are used when building VSTO add-ins
OFFICE_PIA_PACKAGES = {
    "Excel": "@microsoft.office.interop.excel//:lib",
    "Word": "@microsoft.office.interop.word//:lib",
    "Outlook": "@microsoft.office.interop.outlook//:lib",
    "PowerPoint": "@microsoft.office.interop.powerpoint//:lib",
}

def get_office_pia_deps(office_app):
    """
    Returns the appropriate Office PIA dependency for the specified application.

    Args:
        office_app: The Office application name (Excel, Word, Outlook, PowerPoint)

    Returns:
        A list containing the PIA package reference, or empty list if unknown app
    """
    if office_app not in OFFICE_PIA_PACKAGES:
        fail("Unknown Office application: {}. Valid values are: {}".format(
            office_app,
            ", ".join(OFFICE_PIA_PACKAGES.keys()),
        ))

    return [OFFICE_PIA_PACKAGES[office_app]]

# Minimum Office versions and their corresponding PIA versions
OFFICE_VERSIONS = {
    "2013": "15.0",
    "2016": "15.0",  # Same PIA version as 2013
    "2019": "15.0",  # Same PIA version as 2013
    "2021": "15.0",  # Same PIA version as 2013
    "365": "15.0",   # Office 365 uses same PIAs
}

def validate_office_version(version):
    """
    Validates an Office version string.

    Args:
        version: Office version string (e.g., "2016", "365")

    Returns:
        True if valid, fails otherwise
    """
    if version not in OFFICE_VERSIONS:
        fail("Unknown Office version: {}. Valid values are: {}".format(
            version,
            ", ".join(OFFICE_VERSIONS.keys()),
        ))
    return True
