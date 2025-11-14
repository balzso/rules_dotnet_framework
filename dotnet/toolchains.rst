.NET Framework Toolchains
==========================

.. note::
   This documentation is adapted from the original `rules_dotnet <https://github.com/bazelbuild/rules_dotnet>`_ project (commit d672bdb).
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

.. _core: core.bzl
.. _rules_go: https://github.com/bazelbuild/rules_go
.. _go_toolchains: https://github.com/bazelbuild/rules_go/blob/master/go/toolchains.rst
.. _DotnetLibrary: providers.bzl#DotnetLibrary
.. _DotnetResource: providers.bzl#DotnetResource

.. role:: param(literal)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**

The design and implementation is heavily based on rules_go_ `toolchains <go_toolchains_>`_.

-----

Design
------

The .NET Framework toolchain consists of three main layers: `the sdk`_, `the toolchain`_, and `the context`_.

The SDK
~~~~~~~

At the bottom is the .NET Framework SDK. This fork supports .NET Framework 4.7, 4.7.1, and 4.7.2 on Windows.

The frameworks are bound to ``@net_sdk_<version>`` (e.g., ``@net_sdk_net472``). They can be referred to directly if needed, but
in general you should always access it through the toolchain.

The net_register_sdk_ rule is responsible for locating the .NET Framework SDK on the Windows system and adding
just enough of a build file to expose the contents to Bazel.

The toolchain
~~~~~~~~~~~~~

This is a wrapper over the SDK that provides enough extras to match, target and work on a specific
platform. It should be considered an opaque type; you only ever use it through `the context`_.

Declaration
^^^^^^^^^^^

Toolchains are declared using the dotnet_toolchain macro.

Toolchains are pre-declared for all the known combinations of host and target, and the names
are predictable: "<**host**>"

For instance, if the rules_dotnet repository is loaded with its default name,
the following toolchain labels (along with others) will be available:

  .. code:: python

    @io_bazel_rules_dotnet//dotnet/toolchain:net_windows_amd64

The toolchains are not usable until you register them.

Registration
^^^^^^^^^^^^

Normally you would just call dotnet_register_toolchains_ from your WORKSPACE to register all the
pre-declared toolchains, and allow normal selection logic to pick the right one.

It is fine to add more toolchains to the available set if you like. Because the normal
toolchain matching mechanism prefers the first declared match, you can also override individual
toolchains by declaring and registering toolchains with the same constraints *before* calling
dotnet_register_toolchains_.

If you wish to have more control over the toolchains you can instead just make direct
calls to dotnet_register_toolchains_ with only the toolchains you wish to install. You can see an
example of this in `limiting the available toolchains <https://docs.bazel.build/versions/master/toolchains.html#toolchain-resolution>`_.

The context
~~~~~~~~~~~

This is the type you use if you are writing custom rules that need the dotnet toolchain.

Use
^^^

If you are writing a new rule that wants to use the .NET Framework toolchain, you need to do a couple of things.
First, you have to declare that you want to consume the toolchain in the rule declaration:

.. code:: python

  load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_context")

  my_rule = rule(
      _my_rule_impl,
      attrs = {
          ...
         "dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:net_context_data"))
     },
     toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_type_net"],
 )

And then in the rule body, you need to get the toolchain itself and use its action generators:

.. code:: python

  def _my_rule_impl(ctx):
    dotnet = dotnet_context(ctx)


API
---

dotnet_register_toolchains
~~~~~~~~~~~~~~~~~~~~~~~~~~

Installs the .NET Framework toolchains. Call this from your WORKSPACE file.

net_register_sdk
~~~~~~~~~~~~~~~~

Registers .NET Framework SDK.

Searches for .NET Framework using well-known Windows locations and the provided version.
On non-Windows platforms this function doesn't do anything.

+--------------------------------+-----------------------------+------------------------------------+
| **Name**                       | **Type**                    | **Default value**                  |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`net_version`           | :type:`string`              | |mandatory|                        |
+--------------------------------+-----------------------------+------------------------------------+
| The `TFM <https://docs.microsoft.com/en-us/dotnet/standard/frameworks>`_ of the framework.        |
| Supported values: net47, net471, net472                                                           |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`net_roslyn_version`    | :type:`string`              | :value:`NET_ROSLYN_DEFAULT_VERSION`|
+--------------------------------+-----------------------------+------------------------------------+
| The .NET framework is used with independent compiler provided via nuget package                   |
| `Microsoft.Net.Compilers <https://www.nuget.org/packages/Microsoft.Net.Compilers/>`_              |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`tools_version`         | :type:`string`              | :value:`net472`                    |
+--------------------------------+-----------------------------+------------------------------------+
| The version of the framework to use for SDK tools (resgen, mage, signtool, etc.) if different     |
| is expected.                                                                                      |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`name`                  | :type:`string`              | :value:`None`                      |
+--------------------------------+-----------------------------+------------------------------------+
| The name under which the SDK will be registered. If not provided the default @net_sdk_<tfm>       |
| is used.                                                                                          |
+--------------------------------+-----------------------------+------------------------------------+

Example
^^^^^^^

.. code:: python

  load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_register_sdk", "dotnet_register_toolchains")

  # Register .NET Framework 4.7.2 SDK
  net_register_sdk(net_version = "net472")

  # Register all toolchains
  dotnet_register_toolchains()

wix_register_sdk
~~~~~~~~~~~~~~~~

Registers WiX Toolset v5 SDK for building Windows Installer (.msi) packages.

Auto-detects wix.exe from .NET global tools or NuGet cache. Supports explicit path override.

See ``docs/wix.md`` for detailed WiX integration guide.

+--------------------------------+-----------------------------+------------------------------------+
| **Name**                       | **Type**                    | **Default value**                  |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`name`                  | :type:`string`              | :value:`wix_sdk`                   |
+--------------------------------+-----------------------------+------------------------------------+
| The name under which the WiX SDK will be registered.                                              |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`wix_path`              | :type:`string`              | :value:`None`                      |
+--------------------------------+-----------------------------+------------------------------------+
| Optional explicit path to wix.exe. If not provided, auto-detection is performed.                  |
+--------------------------------+-----------------------------+------------------------------------+

vsto_utilities_register
~~~~~~~~~~~~~~~~~~~~~~~~

Registers VSTO Utilities from Visual Studio installation.

Auto-detects Visual Studio installation (2017/2019/2022) and locates Microsoft.Office.Tools.*.Utilities.dll files
required for VSTO installer builds.

See ``docs/vsto.md`` for detailed VSTO development guide.

+--------------------------------+-----------------------------+------------------------------------+
| **Name**                       | **Type**                    | **Default value**                  |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`name`                  | :type:`string`              | :value:`vsto_utilities`            |
+--------------------------------+-----------------------------+------------------------------------+
| The name under which the VSTO Utilities will be registered.                                       |
+--------------------------------+-----------------------------+------------------------------------+
| :param:`vs_path`               | :type:`string`              | :value:`None`                      |
+--------------------------------+-----------------------------+------------------------------------+
| Optional explicit path to Visual Studio installation. If not provided, auto-detection is          |
| performed.                                                                                        |
+--------------------------------+-----------------------------+------------------------------------+

dotnet_context
~~~~~~~~~~~~~~

This collects the information needed to form and return a :type:`DotnetContext` from a rule ctx.
It uses the attributes and the toolchains.
It can only be used in the implementation of a rule that has the dotnet toolchain attached and
the dotnet context data as an attribute.

.. code:: python

  my_rule_net = rule(
      _my_rule_impl,
      attrs = {
          ...
        "dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:net_context_data"))
      },
      toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_type_net"],
  )

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`ctx`                   | :type:`ctx`                 | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The Bazel ctx object for the current rule.                                                       |
+--------------------------------+-----------------------------+-----------------------------------+

The context object
~~~~~~~~~~~~~~~~~~

DotnetContext is never returned by a rule; instead you build one using dotnet_context(ctx) at the
top of any custom Starlark rule that wants to interact with the .NET Framework rules.
It provides all the information needed to create dotnet actions, and create or interact with the
other dotnet providers.

When you get a DotnetContext from a context (see use_) it exposes a number of fields and methods.

All methods take the DotnetContext as the only positional argument; all other arguments, even if
mandatory, must be specified by name, to allow us to re-order and deprecate individual parameters
over time.

Methods
^^^^^^^

* Action generators

  * assembly_
  * resx_

* Helpers

  * declare_file_
  * new_library_
  * new_resource_

Fields
^^^^^^

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`toolchain`             | :type:`DotnetToolchain`                                         |
+--------------------------------+-----------------------------------------------------------------+
| The underlying toolchain. This should be considered an opaque type subject to change.            |
+--------------------------------+-----------------------------------------------------------------+
| :param:`exe_extension`         | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| The suffix to use for all executables in this build mode. Mostly used when generating the output |
| filenames of binary rules.                                                                       |
+--------------------------------+-----------------------------------------------------------------+
| :param:`runner`                | :type:`File`                                                    |
+--------------------------------+-----------------------------------------------------------------+
| The framework launcher binary used to run executables (Windows-specific).                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`mcs`                   | :type:`File`                                                    |
+--------------------------------+-----------------------------------------------------------------+
| The main "csc.exe" (C# compiler) binary used.                                                    |
+--------------------------------+-----------------------------------------------------------------+
| :param:`resgen`                | :type:`File`                                                    |
+--------------------------------+-----------------------------------------------------------------+
| The resource compiler (resgen.exe from Windows SDK).                                             |
+--------------------------------+-----------------------------------------------------------------+
| :param:`stdlib`                | :type:`File`                                                    |
+--------------------------------+-----------------------------------------------------------------+
| The standard library (mscorlib.dll) to use in the build.                                         |
+--------------------------------+-----------------------------------------------------------------+
| :param:`libVersion`            | :type:`string`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| The library version to used (e.g., "v4.7.2").                                                    |
+--------------------------------+-----------------------------------------------------------------+
| :param:`actions`               | :type:`ctx.actions`                                             |
+--------------------------------+-----------------------------------------------------------------+
| The actions structure from the Bazel context, which has all the methods for building new         |
| bazel actions.                                                                                   |
+--------------------------------+-----------------------------------------------------------------+
| :param:`lib`                   | :type:`label`                                                   |
+--------------------------------+-----------------------------------------------------------------+
| The label for directory with the selected libraryVersion assemblies                              |
+--------------------------------+-----------------------------------------------------------------+

assembly
~~~~~~~~

The assembly function adds an action that compiles the set of sources into an assembly.

It returns DotnetLibrary_ provider.

+--------------------------------+--------------------------------+-----------------------------------+
| **Name**                       | **Type**                       | **Default value**                 |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`                 | |mandatory|                       |
+--------------------------------+--------------------------------+-----------------------------------+
| A unique name for this assembly.                                                                    |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`srcs`                  | :type:`File iterable`          | |mandatory|                       |
+--------------------------------+--------------------------------+-----------------------------------+
| An iterable of source code artifacts.                                                               |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`deps`                  | :type:`DotnetLibrary iterable` | :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| An iterable of all directly imported libraries.                                                     |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`out`                   | :type:`string`                 | :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| An alternative name of the output file                                                              |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`resources`             | :type:`DotnetResource iterable`| :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| An iterable of all resources to embed.                                                              |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`executable`            | :type:`bool`                   | :value:`True`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| Determines if an executable or ordinary assembly is produced                                        |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`defines`               | :type:`string iterable`        | :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| A list of defines to be passed to the compiler                                                      |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`unsafe`                | :type:`bool`                   | :value:`False`                    |
+--------------------------------+--------------------------------+-----------------------------------+
| Determines if /unsafe should be passed to the compiler                                              |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`data`                  | :type:`File iterable`          | :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| List of additional files to use as runfiles.                                                        |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`keyfile`               | :type:`File`                   | :value:`None`                     |
+--------------------------------+--------------------------------+-----------------------------------+
| Keyfile to use for signing the assembly.                                                            |
+--------------------------------+--------------------------------+-----------------------------------+

resx
~~~~

The function adds an action that compiles a single .resx file into a .resources file.

It returns DotnetResource_ provider.

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this resource.                                                                 |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`src`               | :type:`label`               | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The .resx source file that is transformed into .resources file.                                  |
| Only :value:`.resx` files are permitted                                                          |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`identifer`         | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| The logical name for the resource; the name that is used to load the resource.                   |
| The default is the basename of the file name (no subfolder).                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`out`               | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| An alternative name of the output file                                                           |
+----------------------------+-----------------------------+---------------------------------------+

declare_file
~~~~~~~~~~~~

This is the equivalent of ctx.actions.declare_file.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`dotnet`                | :type:`DotnetContext`       | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same DotnetContext object you got this function from.                           |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`path`                  | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A path for this file, including the basename of the file.                                        |
+--------------------------------+-----------------------------+-----------------------------------+

new_library
~~~~~~~~~~~

This creates a new DotnetLibrary_.
You can add extra fields to the library by providing extra named parameters to this function;
they will be visible to the resolver when it is invoked.

+--------------------------------+--------------------------------+-----------------------------------+
| **Name**                       | **Type**                       | **Default value**                 |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`                 | |mandatory|                       |
+--------------------------------+--------------------------------+-----------------------------------+
| A unique name for this library.                                                                     |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`dotnet`                | :type:`DotnetContext`          | |mandatory|                       |
+--------------------------------+--------------------------------+-----------------------------------+
| This must be the same DotnetContext object you got this function from.                              |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`deps`                  | :type:`list of DotnetLibrary`  |                                   |
+--------------------------------+--------------------------------+-----------------------------------+
| The direct dependencies of this library.                                                            |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`transitive`            | :type:`depset of DotnetLibrary`|                                   |
+--------------------------------+--------------------------------+-----------------------------------+
| The full set of transitive dependencies. This includes ``deps`` for this                            |
| library and all ``deps`` members transitively reachable through ``deps``.                           |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`result`                | :type:`File`                   |                                   |
+--------------------------------+--------------------------------+-----------------------------------+
| The result to include in DotnetLibrary (used when importing external assemblies)                    |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`pdb`                   | :type:`File`                   |                                   |
+--------------------------------+--------------------------------+-----------------------------------+
| The .pdb file for given library                                                                     |
+--------------------------------+--------------------------------+-----------------------------------+
| :param:`runfiles`              | :type:`depset of Files`        |                                   |
+--------------------------------+--------------------------------+-----------------------------------+
| Runfiles for DotnetLibrary                                                                          |
+--------------------------------+--------------------------------+-----------------------------------+

new_resource
~~~~~~~~~~~~

This creates a new DotnetResource_.
You can add extra fields to the dotnet resource by providing extra named parameters to this function;
they will be visible to the resolver when it is invoked.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A unique name for this resource.                                                                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`dotnet`                | :type:`DotnetContext`       | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same DotnetContext object you got this function from.                           |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`result`                | :type:`File`                | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The .resources file.                                                                             |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`identifier`            | :type:`string`              | :value:`None`                     |
+--------------------------------+-----------------------------+-----------------------------------+
| Identifier passed to -resource flag of csc compiler. If empty the basename of the result         |
| is used.                                                                                         |
+--------------------------------+-----------------------------+-----------------------------------+

stdlib_byname
~~~~~~~~~~~~~

This creates a new DotnetLibrary_.
Looks for given library within imported framework.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`shared`                | :type:`target`              |                                   |
+--------------------------------+-----------------------------+-----------------------------------+
| A target with libraries.                                                                         |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`lib`                   | :type:`target`              |                                   |
+--------------------------------+-----------------------------+-----------------------------------+
| A target with libraries.                                                                         |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`libVersion`            | :type:`string`              |                                   |
+--------------------------------+-----------------------------+-----------------------------------+
| Version of the framework to look for.                                                            |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| Name of the library to look for.                                                                 |
+--------------------------------+-----------------------------+-----------------------------------+
