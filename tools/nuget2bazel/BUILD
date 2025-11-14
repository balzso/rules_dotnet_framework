load("@rules_dotnet_framework//dotnet:defs.bzl", "net_binary")

net_binary(
    name = "nuget2bazel.exe",
    srcs = glob([
        "*.cs",
        "rules/*.cs",
    ]),
    target_framework = "net472",
    visibility = ["//visibility:public"],
    deps = [
        "@commandlineparser//:net",
        "@newtonsoft.json//:net",
        "@nuget.common//:net",
        "@nuget.configuration//:net",
        "@nuget.frameworks//:net",
        "@nuget.packagemanagement.netstandard//:net",
        "@nuget.packaging.core//:net",
        "@nuget.packaging//:net",
        "@nuget.projectmodel//:net",
        "@nuget.protocol//:net",
        "@nuget.resolver//:net",
        "@nuget.versioning//:net",
        "@sharpziplib//:net",
        "@system.reflection.metadataloadcontext//:net",
    ],
)
