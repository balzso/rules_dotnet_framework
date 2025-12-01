load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def dotnet_repositories():
    """Set up external repositories required by rules_dotnet_framework.
    
    This function fetches bazel-skylib (as rules_dotnet_skylib) for WORKSPACE mode.
    In MODULE.bazel mode, @bazel_skylib is used directly via repo_mapping in extensions.bzl.
    """
    maybe(
        http_archive,
        name = "rules_dotnet_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    )
