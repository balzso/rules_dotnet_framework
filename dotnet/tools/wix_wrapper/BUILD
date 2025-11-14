load(
    "@rules_dotnet_framework//dotnet:defs.bzl",
    "DOTNET_NET_FRAMEWORKS",
    "net_binary",
)

[net_binary(
    name = "wix_wrapper_{}.exe".format(framework),
    srcs = [
        "Program.cs",
    ],
    dotnet_context_data = "@rules_dotnet_framework//:net_context_data_{}".format(framework),
    visibility = ["//visibility:public"],
    deps = [
        "@rules_dotnet_framework//dotnet/stdlib.net/{}:system.dll".format(framework),
    ],
) for framework in DOTNET_NET_FRAMEWORKS]
