load("@rules_dotnet_framework//dotnet:defs.bzl", "DOTNET_CORE_FRAMEWORKS", "core_binary")

[core_binary(
    name = "{}_simpleresgen.exe".format(framework),
    srcs = glob(["**/*.cs"]),
    dotnet_context_data = "@rules_dotnet_framework//:core_context_data_{}".format(framework),
    unsafe = True,
    visibility = ["//visibility:public"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.core/{}:libraryset".format(framework),
    ],
) for framework in DOTNET_CORE_FRAMEWORKS]

core_binary(
    name = "simpleresgen.exe",
    srcs = glob(["**/*.cs"]),
    dotnet_context_data = "@rules_dotnet_framework//:core_context_data",
    unsafe = True,
    visibility = ["//visibility:public"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.core:libraryset",
    ],
)
