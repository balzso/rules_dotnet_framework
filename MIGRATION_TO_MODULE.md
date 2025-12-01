# Migration Guide: WORKSPACE to MODULE.bazel

This guide helps you migrate your `rules_dotnet_framework` project from WORKSPACE to MODULE.bazel (Bzlmod).

## ✅ Migration Status: COMPLETE

The `rules_dotnet_framework` project has been successfully migrated to support MODULE.bazel! 

**What's been done:**
- ✅ Created `MODULE.bazel` with all dependencies
- ✅ Created `dotnet/extensions.bzl` with module extensions
- ✅ Created `dotnet/workspace_compat.bzl` for backward compatibility
- ✅ Updated `WORKSPACE` with compatibility notes
- ✅ Updated `README.md` with MODULE.bazel documentation
- ✅ Updated `.bazelrc` to enable Bzlmod by default
- ✅ Made test environment MODULE-aware

**Files created/modified:**
- `MODULE.bazel` - New MODULE definition
- `dotnet/extensions.bzl` - Module extensions for toolchains and repos
- `dotnet/workspace_compat.bzl` - Backward compatibility layer
- `WORKSPACE` - Updated with migration notes
- `README.md` - Added MODULE.bazel setup instructions
- `.bazelrc` - Enabled Bzlmod by default
- `tests/bazel_tests.bzl` - MODULE-aware test environment

## Why Migrate?

**Benefits of MODULE.bazel:**
- ✅ Better dependency management with version resolution
- ✅ Faster builds with improved caching
- ✅ Cleaner dependency graph
- ✅ Future-proof (WORKSPACE is being phased out)
- ✅ Better support for transitive dependencies
- ✅ Official Bazel Central Registry (BCR) integration

**Requirements:**
- Bazel 7.0 or later (recommended: latest stable)
- Windows 10 or later with .NET Framework installed

## Migration Steps

### Step 1: Check Your Bazel Version

```bash
bazel version
```

If you're using Bazel < 7.0, consider upgrading first.

### Step 2: Create MODULE.bazel File

Create a `MODULE.bazel` file in your project root:

```python
"""My .NET Framework Project"""

module(
    name = "my_dotnet_project",
    version = "1.0.0",
)

# Add rules_dotnet_framework dependency
bazel_dep(name = "rules_dotnet_framework", version = "0.1.0")

# If using a local or git version:
# local_path_override(
#     module_name = "rules_dotnet_framework",
#     path = "../rules_dotnet_framework",
# )

# Configure .NET Framework toolchains
toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.toolchain(register_default = True)
toolchain.nugets()
toolchain.sdk()  # Default SDK

# Register specific .NET Framework versions you need
toolchain.sdk(framework = "net472", name = "net_sdk_net472")
toolchain.sdk(framework = "net48", name = "net_sdk_net48")

# If you're building VSTO add-ins
toolchain.vsto(name = "vsto_runtime")

# If you need GAC4 assemblies
toolchain.gac4(
    name = "System.ComponentModel.DataAnnotations",
    token = "31bf3856ad364e35",
    version = "4.0.0.0",
)
```

### Step 3: Enable Bzlmod in .bazelrc

Add to your `.bazelrc` file (or create one):

```bash
# Enable MODULE.bazel (Bzlmod)
common --enable_bzlmod

# Optional: Show more information during migration
common --announce_rc
```

### Step 4: Test the Migration

Try building your project:

```bash
bazel build //...
```

If you encounter issues, see the Troubleshooting section below.

### Step 5: Gradual Transition (Optional)

You can keep both WORKSPACE and MODULE.bazel during the transition:

**In `.bazelrc`:**
```bash
# Try MODULE.bazel first, fall back to WORKSPACE if needed
common --enable_bzlmod
```

Bazel will use MODULE.bazel when available, but can still fall back to WORKSPACE.

### Step 6: Remove WORKSPACE (Final Step)

Once everything works with MODULE.bazel:

1. **Backup your WORKSPACE file** (just in case)
2. Delete or rename your WORKSPACE file
3. Remove WORKSPACE-specific files if any

## Comparison: Before and After

### Before (WORKSPACE)

```python
workspace(name = "my_project")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_dotnet_framework",
    remote = "https://github.com/balzso/rules_dotnet_framework.git",
    branch = "main",
)

load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_repositories")
dotnet_repositories()

load(
    "@rules_dotnet_framework//dotnet:defs.bzl",
    "dotnet_register_toolchains",
    "dotnet_repositories_nugets",
    "net_register_sdk",
    "vsto_runtime_register",
)

dotnet_register_toolchains()
dotnet_repositories_nugets()
vsto_runtime_register(name = "vsto_runtime")
net_register_sdk()
net_register_sdk("net472", name = "net_sdk_net472")
```

### After (MODULE.bazel)

```python
module(
    name = "my_project",
    version = "1.0.0",
)

bazel_dep(name = "rules_dotnet_framework", version = "0.1.0")

toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.toolchain(register_default = True)
toolchain.nugets()
toolchain.vsto(name = "vsto_runtime")
toolchain.sdk()
toolchain.sdk(framework = "net472", name = "net_sdk_net472")
```

Much cleaner! 🎉

## Common Migration Patterns

### Pattern 1: Simple Project

**Before:**
```python
load("@rules_dotnet_framework//dotnet:deps.bzl", "dotnet_repositories")
dotnet_repositories()
load("@rules_dotnet_framework//dotnet:defs.bzl", "dotnet_register_toolchains")
dotnet_register_toolchains()
```

**After:**
```python
bazel_dep(name = "rules_dotnet_framework", version = "0.1.0")
toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.toolchain(register_default = True)
```

### Pattern 2: VSTO Add-in Project

**Before:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", 
     "vsto_runtime_register", 
     "net_register_sdk")
vsto_runtime_register(name = "vsto_runtime")
net_register_sdk("net472", name = "net_sdk_net472")
```

**After:**
```python
toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.vsto(name = "vsto_runtime")
toolchain.sdk(framework = "net472", name = "net_sdk_net472")
```

### Pattern 3: Multiple .NET Framework Versions

**Before:**
```python
load("@rules_dotnet_framework//dotnet:defs.bzl", 
     "DOTNET_NET_FRAMEWORKS",
     "net_register_sdk")

[net_register_sdk(framework, name = "net_sdk_" + framework) 
 for framework in DOTNET_NET_FRAMEWORKS]
```

**After:**
```python
toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.sdk(framework = "net20", name = "net_sdk_net20")
toolchain.sdk(framework = "net35", name = "net_sdk_net35")
toolchain.sdk(framework = "net40", name = "net_sdk_net40")
toolchain.sdk(framework = "net45", name = "net_sdk_net45")
toolchain.sdk(framework = "net472", name = "net_sdk_net472")
toolchain.sdk(framework = "net48", name = "net_sdk_net48")
# ... list only the versions you actually need
```

## Troubleshooting

### Error: "external repository '...' is not defined"

**Cause:** MODULE.bazel extension not properly loaded.

**Solution:** Make sure you have the `use_extension` and proper tag calls:
```python
toolchain = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "toolchain")
toolchain.toolchain(register_default = True)
```

### Error: "no such package '@rules_dotnet_skylib//'"

**Cause:** The dotnet extension hasn't been loaded.

**Solution:** Add the dotnet extension:
```python
dotnet = use_extension("@rules_dotnet_framework//dotnet:extensions.bzl", "dotnet")
dotnet.repositories()
use_repo(dotnet, "rules_dotnet_skylib")
```

### Build is slower than before

**Cause:** First build after migration needs to fetch and cache dependencies.

**Solution:** Subsequent builds will be faster. Consider:
```bash
# Clean and rebuild
bazel clean --expunge
bazel build //...
```

### I need WORKSPACE for other dependencies

**Solution:** You can use both! Bazel supports mixing MODULE.bazel with WORKSPACE:

1. Keep your WORKSPACE file
2. Add MODULE.bazel with `rules_dotnet_framework`
3. MODULE.bazel dependencies take precedence

### Tests fail after migration

**Cause:** Test environment may need adjustment.

**Solution:** The test environment is MODULE-aware. Check:
1. `.bazelrc` has `--enable_bzlmod`
2. Test targets are updated if they reference external repos directly

## Need Help?

If you encounter issues:

1. Check the [rules_dotnet_framework README](README.md)
2. Review the [examples](tests/) in the repository
3. Open an issue on GitHub with:
   - Your Bazel version
   - Your MODULE.bazel content
   - Full error message
   - Minimal reproducible example

## Backward Compatibility

For projects that need to support both WORKSPACE and MODULE.bazel users (e.g., if you're maintaining a library):

```python
# In your WORKSPACE - provide a compatibility layer
load("@rules_dotnet_framework//dotnet:workspace_compat.bzl", "setup_dotnet_framework")
setup_dotnet_framework()
```

This ensures your project works regardless of which system users prefer.

## Timeline

- **Now**: Both WORKSPACE and MODULE.bazel fully supported
- **2025+**: MODULE.bazel recommended for new projects
- **Future**: WORKSPACE support will eventually be deprecated (but not soon)

We recommend migrating when convenient, but there's no immediate urgency.
