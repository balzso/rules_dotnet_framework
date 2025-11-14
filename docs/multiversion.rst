Multiversion
============

.. note::
   This documentation is adapted from the original `rules_dotnet <https://github.com/bazelbuild/rules_dotnet>`_ project (commit d672bdb).
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

.. _net_register_sdk: ../dotnet/toolchains.rst#net_register_sdk

.NET Framework is often used with multiple versions (net47, net471, net472) to support different
Windows platforms or to maintain compatibility with existing deployments.

rules_dotnet_framework supports multiple .NET Framework versions. The version is specified
by the ``dotnet_context_data`` attribute or the ``target_framework`` attribute.

Specifying Framework Version
-----------------------------

**Method 1: Using target_framework attribute (recommended)**

The simplest way to specify the framework version:

.. code:: python

    net_library(
        name = "MyLib.dll",
        srcs = [
            "MyClass.cs",
        ],
        target_framework = "net472",  # or "net47", "net471"
    )

**Method 2: Using dotnet_context_data attribute**

For advanced scenarios where you need explicit control:

.. code:: python

    net_library(
        name = "MyLib.dll",
        srcs = [
            "MyClass.cs",
        ],
        dotnet_context_data = "@io_bazel_rules_dotnet//:net_context_data_net472",
    )

Available Frameworks
--------------------

This fork supports three .NET Framework versions:

- ``net47`` - .NET Framework 4.7
- ``net471`` - .NET Framework 4.7.1
- ``net472`` - .NET Framework 4.7.2 (default)

These are defined in ``dotnet/platform/list.bzl`` as ``DOTNET_NET_FRAMEWORKS``.

Building Multiple Versions
---------------------------

Two techniques are commonly used to build libraries for multiple framework versions:

**Using loops**

This approach uses list comprehension to generate multiple build targets for each framework version:

In WORKSPACE:

.. code:: python

    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_register_sdk", "DOTNET_NET_FRAMEWORKS")

    [net_register_sdk(
        net_version = framework
    ) for framework in DOTNET_NET_FRAMEWORKS]

In BUILD.bazel:

.. code:: python

    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "DOTNET_NET_FRAMEWORKS", "net_library")

    [net_library(
        name = "MyLib-{}.dll".format(framework),
        srcs = [
            "MyClass.cs",
            "Helper.cs",
        ],
        target_framework = framework,
        visibility = ["//visibility:public"],
    ) for framework in DOTNET_NET_FRAMEWORKS]

This generates three targets:
- ``MyLib-net47.dll``
- ``MyLib-net471.dll``
- ``MyLib-net472.dll``

**Using macros**

For more complex scenarios, you can create macros that generate rules for each framework:

In ``defs.bzl``:

.. code:: python

    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_library")

    def multi_framework_library(name, srcs, deps = [], **kwargs):
        """Generates a library for each supported framework version."""
        frameworks = ["net47", "net471", "net472"]

        for framework in frameworks:
            net_library(
                name = "{}-{}".format(name, framework),
                srcs = srcs,
                deps = ["{}-{}".format(d, framework) for d in deps],
                target_framework = framework,
                **kwargs
            )

In BUILD.bazel:

.. code:: python

    load(":defs.bzl", "multi_framework_library")

    multi_framework_library(
        name = "MyLib.dll",
        srcs = [
            "MyClass.cs",
        ],
        deps = [
            "//other:OtherLib.dll",
        ],
        visibility = ["//visibility:public"],
    )

Example: Transitive Dependencies
---------------------------------

When building for multiple framework versions with transitive dependencies,
ensure that all dependencies are also built for the same framework version.

See `tests/examples/example_transitive_lib/BUILD <../tests/examples/example_transitive_lib/BUILD>`_
for a complete working example.

.. code:: python

    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "DOTNET_NET_FRAMEWORKS", "net_library")

    # Base library
    [net_library(
        name = "TransitiveClass-{}.dll".format(framework),
        srcs = ["TransitiveClass.cs"],
        target_framework = framework,
        visibility = ["//visibility:public"],
    ) for framework in DOTNET_NET_FRAMEWORKS]

    # Dependent library
    [net_library(
        name = "MyClass-{}.dll".format(framework),
        srcs = ["MyClass.cs"],
        deps = [":TransitiveClass-{}.dll".format(framework)],
        target_framework = framework,
        visibility = ["//visibility:public"],
    ) for framework in DOTNET_NET_FRAMEWORKS]

Selecting Framework at Build Time
----------------------------------

You can also use Bazel's config_setting to select the framework version at build time:

.. code:: python

    config_setting(
        name = "net47",
        values = {"define": "framework=net47"},
    )

    config_setting(
        name = "net472",
        values = {"define": "framework=net472"},
    )

    net_library(
        name = "MyLib.dll",
        srcs = ["MyClass.cs"],
        target_framework = select({
            ":net47": "net47",
            ":net472": "net472",
            "//conditions:default": "net472",
        }),
    )

Then build with:

.. code:: bash

    bazel build --define=framework=net47 //path/to:MyLib.dll

Runtime Considerations
----------------------

Please take into consideration the `runtime limitations <runtime.rst>`_, particularly
regarding the Global Assembly Cache (GAC) and version conflicts.

When mixing framework versions in a single project, be aware that all code will run
on the .NET Framework version installed on the target machine, regardless of which
version was used to compile the assemblies.
