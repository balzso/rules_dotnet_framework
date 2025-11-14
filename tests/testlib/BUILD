load("@rules_dotnet_framework//dotnet:defs.bzl", "core_library")

core_library(
    name = "testlib.dll",
    srcs = [
        "BazelTestBase.cs",
        "ProcessAsyncHelper.cs",
    ],
    dotnet_context_data = "@rules_dotnet_framework//:core_context_data",
    visibility = ["//visibility:public"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.core:libraryset",
        "@xunit.assert//:netcoreapp2.0_core",
        "@xunit.extensibility.core//:netcoreapp2.0_core",
        "@xunit.extensibility.execution//:netcoreapp2.0_core",
    ],
)
