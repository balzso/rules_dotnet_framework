load("@rules_dotnet_framework//dotnet:defs.bzl", "DOTNET_NET_FRAMEWORKS", "net_binary")

[net_binary(
    name = "{}_simpleresgen.exe".format(framework),
    srcs = glob(["**/*.cs"]),
    target_framework = framework,
    dotnet_context_data = "@rules_dotnet_framework//:net_context_data_{}".format(framework),
    unsafe = True,
    visibility = ["//visibility:public"],
) for framework in DOTNET_NET_FRAMEWORKS]

net_binary(
    name = "simpleresgen.exe",
    srcs = glob(["**/*.cs"]),
    target_framework = "net472",
    dotnet_context_data = "@rules_dotnet_framework//:net_context_data_net472",
    unsafe = True,
    visibility = ["//visibility:public"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.net:system.dll",
    ],
)
