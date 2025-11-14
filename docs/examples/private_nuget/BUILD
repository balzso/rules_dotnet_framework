load("@rules_dotnet_framework//dotnet:defs.bzl", "core_xunit_test")

package(default_visibility = ["//visibility:public"])

core_xunit_test(
    name = "custom_nuget.dll",
    srcs = glob(["**/*.cs"]),
    nowarn = ["CS1701"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.core:libraryset",
        "@xunit.assert//:core",
        "@xunit.extensibility.core//:core",
        "@xunit.extensibility.execution//:core",
        "@system.buffers.primitives//:core",
    ],
)
