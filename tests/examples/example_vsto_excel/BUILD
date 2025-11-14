load("@rules_dotnet_framework//dotnet:defs.bzl", "net_vsto_addin")

# Example VSTO Excel Add-in
#
# This demonstrates how to build a simple Excel add-in using the net_vsto_addin rule.
#
# Note: To use this example, you need to:
# 1. Have the Office PIAs available (via NuGet or installed Office)
# 2. Have the VSTO runtime installed (comes with Visual Studio)
# 3. Configure WORKSPACE with vsto_nuget_packages()

net_vsto_addin(
    name = "ExampleVstoExcel.dll",
    srcs = [
        "Simple.cs",
    ],
    # Office application target
    office_app = "Excel",
    office_version = "2016",  # Minimum Office 2016

    # .NET Framework version (VSTO requires .NET Framework 4.x)
    target_framework = "net472",

    # Strong name signing (recommended for VSTO add-ins)
    # keyfile = "TestKey.snk",

    # Dependencies (manually specified for now)
    # In a full implementation, these would be automatically added based on office_app
    deps = [
        # Note: Uncomment these when WORKSPACE is properly configured
        # "@microsoft.office.interop.excel//:lib",
        # "@vsto_runtime//:Microsoft.Office.Tools.Common",
        # "@vsto_runtime//:Microsoft.Office.Tools.Excel",
        # "@vsto_runtime//:Microsoft.Office.Tools",
    ],

    # Generate ClickOnce manifests
    generate_manifests = False,  # Disabled until manifest generation is fully integrated

    # Optional: Code signing certificate
    # signing_cert = "cert.pfx",
    # cert_password = "password",

    # Optional: Installation URL for network deployment
    # install_url = "http://myserver/addins/ExampleVstoExcel/",

    visibility = ["//visibility:public"],
)
