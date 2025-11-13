"""NuGet package declarations for VSTO and Office PIAs"""

load("@rules_dotnet//dotnet:defs.bzl", "nuget_package")

def vsto_nuget_packages():
    """Declares NuGet packages required for VSTO development"""

    # Office Primary Interop Assemblies (PIAs)
    nuget_package(
        name = "microsoft.office.interop.excel",
        package = "Microsoft.Office.Interop.Excel",
        version = "15.0.4795.1001",
        sha256 = "59f3e3866bc278ecd2d1e4b8f1d2b3c2e5e8f4f0f4e0c4e0c4e0c4e0c4e0c4e0",  # TODO: Get actual SHA256
        core_lib = {
            "net47": "lib/net20/Microsoft.Office.Interop.Excel.dll",
            "net471": "lib/net20/Microsoft.Office.Interop.Excel.dll",
            "net472": "lib/net20/Microsoft.Office.Interop.Excel.dll",
        },
        core_deps = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
        core_files = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
    )

    nuget_package(
        name = "microsoft.office.interop.word",
        package = "Microsoft.Office.Interop.Word",
        version = "15.0.4797.1003",
        sha256 = "59f3e3866bc278ecd2d1e4b8f1d2b3c2e5e8f4f0f4e0c4e0c4e0c4e0c4e0c4e0",  # TODO: Get actual SHA256
        core_lib = {
            "net47": "lib/net20/Microsoft.Office.Interop.Word.dll",
            "net471": "lib/net20/Microsoft.Office.Interop.Word.dll",
            "net472": "lib/net20/Microsoft.Office.Interop.Word.dll",
        },
        core_deps = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
        core_files = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
    )

    nuget_package(
        name = "microsoft.office.interop.outlook",
        package = "Microsoft.Office.Interop.Outlook",
        version = "15.0.4797.1003",
        sha256 = "59f3e3866bc278ecd2d1e4b8f1d2b3c2e5e8f4f0f4e0c4e0c4e0c4e0c4e0c4e0",  # TODO: Get actual SHA256
        core_lib = {
            "net47": "lib/net20/Microsoft.Office.Interop.Outlook.dll",
            "net471": "lib/net20/Microsoft.Office.Interop.Outlook.dll",
            "net472": "lib/net20/Microsoft.Office.Interop.Outlook.dll",
        },
        core_deps = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
        core_files = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
    )

    nuget_package(
        name = "microsoft.office.interop.powerpoint",
        package = "Microsoft.Office.Interop.PowerPoint",
        version = "15.0.4420.1017",
        sha256 = "59f3e3866bc278ecd2d1e4b8f1d2b3c2e5e8f4f0f4e0c4e0c4e0c4e0c4e0c4e0",  # TODO: Get actual SHA256
        core_lib = {
            "net47": "lib/net20/Microsoft.Office.Interop.PowerPoint.dll",
            "net471": "lib/net20/Microsoft.Office.Interop.PowerPoint.dll",
            "net472": "lib/net20/Microsoft.Office.Interop.PowerPoint.dll",
        },
        core_deps = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
        core_files = {
            "net47": [],
            "net471": [],
            "net472": [],
        },
    )
