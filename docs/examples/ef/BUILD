load("@rules_dotnet_framework//dotnet:defs.bzl", "core_xunit_test")

package(default_visibility = ["//visibility:public"])

core_xunit_test(
    name = "dotnet_ef.dll",
    srcs = glob(["**/*.cs"]),
    nowarn = ["CS1701"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.core:Microsoft.AspNetCore.App",
        "@rules_dotnet_framework//dotnet/stdlib.core:libraryset",
        "@microsoft.entityframeworkcore//:core",
        "@xunit.assert//:core",
        "@xunit.extensibility.core//:core",
        "@xunit.extensibility.execution//:core",
    ],
)
