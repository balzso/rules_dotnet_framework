"""Actions for Authenticode signing of ClickOnce manifests"""

def emit_sign_manifest(
        dotnet,
        manifest,
        cert_file = None,
        cert_password = None,
        cert_thumbprint = None,
        timestamp_url = "http://timestamp.digicert.com"):
    """Signs a ClickOnce manifest with an Authenticode signature.

    Args:
        dotnet: The dotnet context from dotnet_context()
        manifest: The manifest File object to sign (can be .manifest or .vsto)
        cert_file: Optional PFX certificate file
        cert_password: Optional certificate password
        cert_thumbprint: Optional certificate thumbprint (for certificate store)
        timestamp_url: URL for timestamping service (default: DigiCert)

    Returns:
        File object for the signed manifest (same as input, modified in-place)
    """

    # Get signtool.exe
    signtool = dotnet.signtool
    signtool_wrapper = dotnet.signtool_wrapper

    # signtool.exe command line format for signing:
    #
    # Using PFX file:
    # signtool.exe sign /f <cert.pfx> /p <password> /t <timestamp_url> <file>
    #
    # Using certificate store:
    # signtool.exe sign /sha1 <thumbprint> /t <timestamp_url> <file>
    #
    # For ClickOnce manifests, we must use:
    # signtool.exe sign /f <cert.pfx> /p <password> /t <timestamp_url> /fd SHA256 <file>

    args = dotnet.actions.args()
    args.add(signtool.path)  # Path to signtool.exe
    args.add("sign")

    # Certificate source
    if cert_file:
        args.add("/f")
        args.add(cert_file.path)
        if cert_password:
            args.add("/p")
            args.add(cert_password)
    elif cert_thumbprint:
        args.add("/sha1")
        args.add(cert_thumbprint)
    else:
        # No certificate specified - this is an error
        fail("Either cert_file or cert_thumbprint must be provided for signing")

    # Timestamping (optional but highly recommended)
    if timestamp_url:
        args.add("/t")
        args.add(timestamp_url)

    # File digest algorithm (SHA256 recommended for modern certificates)
    args.add("/fd")
    args.add("SHA256")

    # File to sign
    args.add(manifest.path)

    # Note: signtool modifies the file in-place, so we need to use a copy
    # to maintain Bazel's immutability requirements
    signed_manifest = dotnet.actions.declare_file(manifest.basename + ".signed")

    # Copy the manifest first, then sign the copy
    dotnet.actions.run_shell(
        command = "copy /Y \"{}\" \"{}\" && {} {}".format(
            manifest.path.replace("/", "\\"),
            signed_manifest.path.replace("/", "\\"),
            signtool_wrapper.path.replace("/", "\\"),
            " ".join([a for a in [
                signtool.path,
                "sign",
                "/f " + cert_file.path if cert_file else None,
                "/p " + cert_password if cert_password else None,
                "/sha1 " + cert_thumbprint if cert_thumbprint else None,
                "/t " + timestamp_url if timestamp_url else None,
                "/fd SHA256",
                "\"" + signed_manifest.path.replace("/", "\\") + "\"",
            ] if a]),
        ),
        inputs = [manifest, signtool] + ([cert_file] if cert_file else []),
        outputs = [signed_manifest],
        mnemonic = "DotnetSignManifest",
        progress_message = "Signing manifest {}".format(manifest.basename),
    )

    return signed_manifest
