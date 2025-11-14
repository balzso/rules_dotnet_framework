load("@rules_dotnet_framework//dotnet:defs.bzl", "DOTNET_NET_FRAMEWORKS", "dotnet_binary", "net_binary")

dotnet_binary(
    name = "hello_tool.exe",
    srcs = [
        "MyTool.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass.dll",
        "@rules_dotnet_framework//dotnet/stdlib:system.dll",
    ],
)

[net_binary(
    name = "hello_tool_net_{}.exe".format(framework),
    srcs = [
        "MyTool.cs",
    ],
    dotnet_context_data = "@rules_dotnet_framework//:net_context_data_{}".format(framework),
    deps = [
        "//tests/examples/example_lib:MyClass-net_{}.dll".format(framework),
    ],
) for framework in DOTNET_NET_FRAMEWORKS]

genrule(
    name = "hello_single_output",
    outs = [
        "hello_world.txt",
    ],
    cmd = "$(location :hello_tool.exe) $@",
    tools = [
        ":hello_tool.exe",
    ],
)

genrule(
    name = "hello_multiple_outputs",
    outs = [
        "hello_world_1.txt",
        "hello_world_2.txt",
    ],
    cmd = "$(location :hello_tool.exe) $(OUTS)",
    tools = [
        ":hello_tool.exe",
    ],
)
