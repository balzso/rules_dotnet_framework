DotnetLibrary = provider(
    doc = "A represenatation of the dotnet assembly (regardless of framework used). See dotnet/providers.rst#DotnetLibrary for full documentation",
    fields = {
        "label": "Label of the rule used to create this DotnetLibrary",
        "name": "Name of the assembly (label.name if not provided)",
        "version": "Version number of the library. Tuple with 5 elements",
        "ref": "Reference assembly for this DotnetLibrary. Must be set to ctx.attr.ref or result if not provided",
        "deps": "The direct dependencies of this library",
        "result": "The assembly file",
        "pdb": "The pdb file (with compilation mode dbg)",
        "runfiles": "The depset of direct runfiles (File)",
        "transitive": "The full set of transitive dependencies. This does not include this assembly. List of DotnetLibrary",
        "embed_interop_types": "If True, embed COM interop types using /link instead of /reference (default: False)",
    },
)

DotnetResource = provider()
"""
A represenatation of the dotnet compiled resource (.resources).
See dotnet/providers.rst#DotnetResource for full documentation.
"""

DotnetResourceList = provider()
"""
A represenatation of the lsit of compiled resource (.resources).
See dotnet/providers.rst#DotnetResourceList for full documentation.
"""

DotnetContextData = provider(
    doc = "Context data for dotnet toolchain configuration",
    fields = {
        "_mcs_bin": "Mono C# compiler binary",
        "_mono_bin": "Mono runtime binary",
        "_lib": "Dotnet libraries",
        "_tools": "Dotnet tools",
        "_shared": "Shared configuration",
        "_host": "Host platform",
        "_libVersion": "Library version",
        "_toolchain_type": "Toolchain type identifier",
        "_framework": "Target framework version",
        "_runner": "Test runner configuration",
        "_csc": "C# compiler (csc.exe) configuration",
        "_runtime": "Runtime configuration",
        "_mage_wrapper": "Mage tool wrapper for manifest generation",
    },
)
