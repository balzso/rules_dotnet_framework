"""Module extensions for rules_dotnet_framework

This file provides Bzlmod (MODULE.bazel) support for rules_dotnet_framework.
It defines two main extensions:
- dotnet: For managing external repositories
- toolchain: For registering toolchains, SDKs, and runtime dependencies
"""

load("@rules_dotnet_framework//dotnet/private:repositories.bzl", "dotnet_repositories")
load("@rules_dotnet_framework//dotnet/toolchain:toolchains.bzl", "dotnet_register_toolchains", "net_register_sdk")
load("@rules_dotnet_framework//dotnet/private:sdk_wix.bzl", "wix_register_sdk")
load("@rules_dotnet_framework//dotnet/private:vsto_utilities.bzl", "vsto_utilities_register")
load("@rules_dotnet_framework//dotnet/private/vsto:vsto_runtime.bzl", "vsto_runtime_register")
load("@rules_dotnet_framework//dotnet/private:nugets.bzl", "dotnet_repositories_nugets")
load("@rules_dotnet_framework//dotnet/private/rules:gac_net.bzl", "net_gac4")
load("@rules_dotnet_framework//dotnet/private/rules:nuget.bzl", "dotnet_nuget_new")
load("@rules_dotnet_framework//dotnet/platform:list.bzl", "DOTNET_NET_FRAMEWORKS")

# Repository extension for external dependencies
_dotnet_repos = tag_class(attrs = {})

def _dotnet_extension_impl(module_ctx):
    """Implementation of the dotnet module extension.
    
    This extension handles fetching external dependencies like bazel-skylib.
    
    Args:
        module_ctx: The module context provided by Bazel
        
    Returns:
        Extension metadata with direct dependencies
    """
    
    # Fetch external dependencies (e.g., bazel-skylib)
    dotnet_repositories()
    
    # Process repository tags if any
    for mod in module_ctx.modules:
        for _ in mod.tags.repositories:
            pass  # Currently no-op, but allows for future customization
    
    return module_ctx.extension_metadata(
        root_module_direct_deps = ["rules_dotnet_skylib"],
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

dotnet = module_extension(
    implementation = _dotnet_extension_impl,
    tag_classes = {
        "repositories": _dotnet_repos,
    },
)

# Toolchain extension tag classes
_toolchain_tag = tag_class(
    attrs = {
        "register_default": attr.bool(
            default = True,
            doc = "Whether to register default .NET Framework toolchains",
        ),
    },
)

_sdk_tag = tag_class(
    attrs = {
        "framework": attr.string(
            doc = "The .NET Framework version (e.g., 'net472', 'net48')",
        ),
        "name": attr.string(
            doc = "The name for the SDK repository",
        ),
    },
)

_vsto_tag = tag_class(
    attrs = {
        "name": attr.string(
            default = "vsto_runtime",
            doc = "The name for the VSTO runtime repository",
        ),
    },
)

_nugets_tag = tag_class(attrs = {})

_nuget_register_tag = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
            doc = "The repository name for the NuGet package",
        ),
        "package": attr.string(
            mandatory = True,
            doc = "The NuGet package name",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "The NuGet package version",
        ),
        "sha256": attr.string(
            doc = "The SHA256 hash of the package",
        ),
    },
)

_gac4_tag = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
            doc = "The assembly name in GAC4",
        ),
        "token": attr.string(
            mandatory = True,
            doc = "The public key token",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "The assembly version",
        ),
    },
)

_wix_tag = tag_class(
    attrs = {
        "name": attr.string(
            default = "wix_sdk",
            doc = "The name of the WiX SDK repository",
        ),
        "wix_path": attr.string(
            doc = "Explicit path to wix.exe. If not specified, auto-detection will be attempted.",
        ),
    },
)

def _toolchain_extension_impl(module_ctx):
    """Implementation of the toolchain module extension.
    
    This extension handles:
    - Registering .NET Framework toolchains
    - Registering SDKs for different .NET Framework versions
    - Registering VSTO runtime for VSTO add-in development
    - Fetching NuGet repositories
    - Registering GAC4 assemblies
    
    Args:
        module_ctx: The module context provided by Bazel
        
    Returns:
        Extension metadata
    """
    
    # Track if we've registered defaults to avoid duplication
    toolchains_registered = False
    nugets_registered = False
    nuget_repos = []
    registered_nugets = {}  # Track registered NuGet packages to avoid duplicates
    
    # Process all modules and their tags
    for mod in module_ctx.modules:
        # Register toolchains
        for tag in mod.tags.toolchain:
            if tag.register_default and not toolchains_registered:
                # Note: In Bzlmod, toolchains are registered via register_toolchains() 
                # directive in the root module's MODULE.bazel, not here in the extension.
                # We just track that default toolchains were requested.
                toolchains_registered = True
        
        # Register SDKs
        for tag in mod.tags.sdk:
            if tag.framework and tag.name:
                net_register_sdk(tag.framework, name = tag.name)
            elif not tag.framework and not tag.name:
                # Default SDK registration
                net_register_sdk()
        
        # Register VSTO runtime
        for tag in mod.tags.vsto:
            vsto_runtime_register(name = tag.name)
        
        # Register NuGet repositories
        for _ in mod.tags.nugets:
            if not nugets_registered:
                dotnet_repositories_nugets()
                nugets_registered = True
        
        # Register individual NuGet packages (with deduplication)
        for tag in mod.tags.nuget_register:
            # Check if this package was already registered
            if tag.name in registered_nugets:
                # Skip duplicate registration
                continue
            
            dotnet_nuget_new(
                name = tag.name,
                package = tag.package,
                version = tag.version,
                sha256 = tag.sha256 if tag.sha256 else "",
            )
            registered_nugets[tag.name] = True
            nuget_repos.append(tag.name)
        
        # Register GAC4 assemblies
        for tag in mod.tags.gac4:
            net_gac4(
                name = tag.name,
                token = tag.token,
                version = tag.version,
            )
        
        # Register WiX SDK
        for tag in mod.tags.wix:
            wix_register_sdk(
                name = tag.name,
                wix_path = tag.wix_path if tag.wix_path else None,
            )
    
    return module_ctx.extension_metadata(
        root_module_direct_deps = [],
        root_module_direct_dev_deps = [],
    )

toolchain = module_extension(
    implementation = _toolchain_extension_impl,
    tag_classes = {
        "toolchain": _toolchain_tag,
        "sdk": _sdk_tag,
        "vsto": _vsto_tag,
        "nugets": _nugets_tag,
        "nuget_register": _nuget_register_tag,
        "gac4": _gac4_tag,
        "wix": _wix_tag,
    },
)
