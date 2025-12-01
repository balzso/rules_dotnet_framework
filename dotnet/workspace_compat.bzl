"""Backward compatibility layer for WORKSPACE users.

This file provides a simple one-call setup for projects still using WORKSPACE
instead of MODULE.bazel. This allows for a gradual migration path.

Usage in WORKSPACE:
    load("@rules_dotnet_framework//dotnet:workspace_compat.bzl", "setup_dotnet_framework")
    setup_dotnet_framework()

Or for more control:
    load("@rules_dotnet_framework//dotnet:workspace_compat.bzl", "setup_dotnet_framework_custom")
    setup_dotnet_framework_custom(
        register_default_toolchains = True,
        register_nugets = True,
        register_vsto = True,
        register_all_sdks = True,
    )
"""

load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_repositories")
load(
    "@rules_dotnet_framework//dotnet:defs.bzl",
    "DOTNET_NET_FRAMEWORKS",
    "dotnet_register_toolchains",
    "dotnet_repositories_nugets",
    "net_register_sdk",
    "vsto_runtime_register",
)

def setup_dotnet_framework():
    """One-call setup for WORKSPACE users.
    
    This function sets up everything needed for .NET Framework development:
    - External repositories (bazel-skylib)
    - Default toolchains
    - NuGet repositories
    - VSTO runtime
    - Default .NET Framework SDK
    - All supported .NET Framework version SDKs
    """
    dotnet_repositories()
    dotnet_register_toolchains()
    dotnet_repositories_nugets()
    vsto_runtime_register(name = "vsto_runtime")
    
    # Register default SDK
    net_register_sdk()
    
    # Register all supported .NET Framework versions
    for framework in DOTNET_NET_FRAMEWORKS:
        net_register_sdk(
            framework,
            name = "net_sdk_" + framework,
        )

def setup_dotnet_framework_custom(
        register_default_toolchains = True,
        register_nugets = True,
        register_vsto = True,
        register_all_sdks = True,
        register_default_sdk = True,
        sdk_versions = None):
    """Customizable setup for WORKSPACE users.
    
    Args:
        register_default_toolchains: Whether to register default .NET Framework toolchains
        register_nugets: Whether to fetch NuGet repositories
        register_vsto: Whether to register VSTO runtime for add-in development
        register_all_sdks: Whether to register all supported .NET Framework versions
        register_default_sdk: Whether to register the default .NET Framework SDK
        sdk_versions: List of specific .NET Framework versions to register (e.g., ["net472", "net48"])
                     If None and register_all_sdks is True, all versions are registered
    """
    # Always need repositories
    dotnet_repositories()
    
    if register_default_toolchains:
        dotnet_register_toolchains()
    
    if register_nugets:
        dotnet_repositories_nugets()
    
    if register_vsto:
        vsto_runtime_register(name = "vsto_runtime")
    
    if register_default_sdk:
        net_register_sdk()
    
    if register_all_sdks:
        for framework in DOTNET_NET_FRAMEWORKS:
            net_register_sdk(
                framework,
                name = "net_sdk_" + framework,
            )
    elif sdk_versions:
        for framework in sdk_versions:
            net_register_sdk(
                framework,
                name = "net_sdk_" + framework,
            )
