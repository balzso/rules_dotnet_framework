.NET Framework Rules
=====================

.. note::
   This documentation is adapted from the original `rules_dotnet <https://github.com/bazelbuild/rules_dotnet>`_ project (commit d672bdb).
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

.. _test_filter: https://docs.bazel.build/versions/master/user-manual.html#flag--test_filter
.. _test_arg: https://docs.bazel.build/versions/master/user-manual.html#flag--test_arg
.. _DotnetLibrary: providers.rst#DotnetLibrary
.. _DotnetResource: providers.rst#DotnetResource
.. _dotnet_nuget_new: workspace.rst#dotnet_nuget_new

.. role:: param(literal)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**

These are the core .NET Framework rules for Bazel, providing support for building .NET Framework 4.7-4.7.2 projects on Windows.

.. contents:: :depth: 2

-----

API
---

net_library
~~~~~~~~~~~

Builds a .NET Framework class library (.dll) from a set of C# source files.

Providers
^^^^^^^^^

* DotnetLibrary_
* DotnetResource_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule. It must have .dll extension.                                        |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The direct dependencies of this library.                                                         |
| These may be net_library rules or compatible rules with the DotnetLibrary_ provider.             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`resources`         | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of resources to compile with. Usually provided via reference to net_resx                |
| or the rules compatible with DotnetResource_ provider                                            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`srcs`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of .cs source files that are compiled to create the assembly.                           |
| Only :value:`.cs` files are permitted                                                            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`out`               | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| An alternative name of the output file                                                           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`defines`           | :type:`string_list`         | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of defines passed via /define compiler option                                           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`unsafe`            | :type:`bool`                | :value:`False`                        |
+----------------------------+-----------------------------+---------------------------------------+
| If true passes /unsafe flag to the compiler                                                      |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`keyfile`           | :type:`label`               | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The key to sign the assembly with.                                                               |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`data`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of additional files to include in the list of runfiles for compile assembly             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`nowarn`            | :type:`string_list`         | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of warnings to be ignored. The warnings are passed to -nowarn compiler option.          |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`langversion`       | :type:`string`              | :value:`latest`                       |
+----------------------------+-----------------------------+---------------------------------------+
| Version of the language to use. See                                                              |
| https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`version`           | :type:`string`              | :value:``                             |
+----------------------------+-----------------------------+---------------------------------------+
| Version to be set for the assembly. The version is set by compiling in AssemblyVersion attribute |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`target_framework`  | :type:`string`              | :value:`net472`                       |
+----------------------------+-----------------------------+---------------------------------------+
| Target .NET Framework version. Supported values: net47, net471, net472                           |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_library(
      name = "MyClass.dll",
      srcs = [
          "MyClass.cs",
          "Helper.cs",
      ],
      deps = [
          "//examples/example_lib:OtherLib.dll",
          "@newtonsoft.json//:lib",
      ],
      target_framework = "net472",
      visibility = ["//visibility:public"],
  )

net_binary
~~~~~~~~~~

Builds a .NET Framework executable (.exe) from a set of C# source files.
You can run the binary with ``bazel run``, or you can build it with ``bazel build`` and run it directly.

Providers
^^^^^^^^^

* DotnetLibrary_
* DotnetResource_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule. It must have .exe extension.                                        |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The direct dependencies of this library.                                                         |
| These may be net_library rules or compatible rules with the DotnetLibrary_ provider.             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`resources`         | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of resources to compile with. Usually provided via reference to net_resx                |
| or the rules compatible with DotnetResource_ provider                                            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`srcs`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of .cs source files that are compiled to create the assembly.                           |
| Only :value:`.cs` files are permitted                                                            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`out`               | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| An alternative name of the output file                                                           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`defines`           | :type:`string_list`         | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of defines passed via /define compiler option                                           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`unsafe`            | :type:`bool`                | :value:`False`                        |
+----------------------------+-----------------------------+---------------------------------------+
| If true passes /unsafe flag to the compiler                                                      |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`keyfile`           | :type:`label`               | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The key to sign the assembly with.                                                               |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`data`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of additional files to be included as runfiles for the generated executable             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`nowarn`            | :type:`string_list`         | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of warnings to be ignored. The warnings are passed to -nowarn compiler option.          |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`langversion`       | :type:`string`              | :value:`latest`                       |
+----------------------------+-----------------------------+---------------------------------------+
| Version of the language to use. See                                                              |
| https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`version`           | :type:`string`              | :value:``                             |
+----------------------------+-----------------------------+---------------------------------------+
| Version to be set for the assembly. The version is set by compiling in AssemblyVersion attribute |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`target_framework`  | :type:`string`              | :value:`net472`                       |
+----------------------------+-----------------------------+---------------------------------------+
| Target .NET Framework version. Supported values: net47, net471, net472                           |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_binary(
      name = "MyApp.exe",
      srcs = [
          "Program.cs",
      ],
      deps = [
          "//examples/example_lib:MyClass.dll",
          "@newtonsoft.json//:lib",
      ],
      target_framework = "net472",
      visibility = ["//visibility:public"],
  )

net_nunit3_test, net_xunit_test
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Builds a set of tests that can be run with ``bazel test``.

- ``net_nunit3_test`` uses NUnit3 test framework
- ``net_xunit_test`` uses xUnit test framework

To run all tests in the workspace, and print output on failure, run:

::

  bazel test --test_output=errors //...

You can run specific tests by passing the `--test_filter=pattern <test_filter_>`_ argument to Bazel.
You can pass arguments to tests by passing `--test_arg=arg <test_arg_>`_ arguments to Bazel.

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+--------------------------------------------+
| **Name**                   | **Type**                    | **Default value**                          |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                                |
+----------------------------+-----------------------------+--------------------------------------------+
| A unique name for this rule. It must have .dll extension.                                             |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                              |
+----------------------------+-----------------------------+--------------------------------------------+
| The direct dependencies of this library.                                                              |
| These may be net_library rules or compatible rules with the DotnetLibrary_ provider.                  |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`resources`         | :type:`label_list`          | :value:`None`                              |
+----------------------------+-----------------------------+--------------------------------------------+
| The list of resources to compile with. Usually provided via reference to net_resx                     |
| or the rules compatible with DotnetResource_ provider                                                 |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`srcs`              | :type:`label_list`          | :value:`None`                              |
+----------------------------+-----------------------------+--------------------------------------------+
| The list of .cs source files that are compiled to create the assembly.                                |
| Only :value:`.cs` files are permitted                                                                 |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`out`               | :type:`string`              | :value:`""`                                |
+----------------------------+-----------------------------+--------------------------------------------+
| An alternative name of the output file                                                                |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`defines`           | :type:`string_list`         | :value:`None`                              |
+----------------------------+-----------------------------+--------------------------------------------+
| The list of defines passed via /define compiler option                                                |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`testlauncher`      | :type:`Label`               | :value:`<as required by unit framework>`   |
+----------------------------+-----------------------------+--------------------------------------------+
| The test launcher executable to use                                                                   |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`nowarn`            | :type:`string_list`         | :value:`None`                              |
+----------------------------+-----------------------------+--------------------------------------------+
| The list of warnings to be ignored. The warnings are passed to -nowarn compiler option.               |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`langversion`       | :type:`string`              | :value:`latest`                            |
+----------------------------+-----------------------------+--------------------------------------------+
| Version of the language to use. See                                                                   |
| https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version          |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`version`           | :type:`string`              | :value:``                                  |
+----------------------------+-----------------------------+--------------------------------------------+
| Version to be set for the assembly. The version is set by compiling in AssemblyVersion attribute      |
+----------------------------+-----------------------------+--------------------------------------------+
| :param:`target_framework`  | :type:`string`              | :value:`net472`                            |
+----------------------------+-----------------------------+--------------------------------------------+
| Target .NET Framework version. Supported values: net47, net471, net472                                |
+----------------------------+-----------------------------+--------------------------------------------+

Test example
^^^^^^^^^^^^

.. code:: python

    net_nunit3_test(
        name = "MyTest.dll",
        srcs = [
            "MyTest.cs",
        ],
        deps = [
            "//examples/example_lib:MyClass.dll",
            "@nunit//:lib",
        ],
        target_framework = "net472",
    )

    net_xunit_test(
        name = "MyXunitTest.dll",
        srcs = [
            "MyXunitTest.cs",
        ],
        deps = [
            "//examples/example_lib:MyClass.dll",
            "@xunit.assert//:lib",
        ],
        target_framework = "net472",
    )

net_vsto_addin
~~~~~~~~~~~~~~

Builds a VSTO (Visual Studio Tools for Office) add-in for Microsoft Office applications.
This rule compiles a .NET Framework assembly with Office interop dependencies, generates
application and deployment manifests, and optionally signs the assembly and manifests.

See ``docs/vsto.md`` for detailed VSTO development guide.

Providers
^^^^^^^^^

* DotnetLibrary_
* DotnetResource_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule. It must have .dll extension.                                        |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`srcs`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of .cs source files that are compiled to create the add-in.                             |
| Only :value:`.cs` files are permitted                                                            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| Additional dependencies beyond the automatic Office PIAs and VSTO runtime.                       |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`resources`         | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of resources to compile with (e.g., Ribbon XML, images).                                |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`office_app`        | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| Target Office application. Supported values: Excel, Word, Outlook, PowerPoint                    |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`office_version`    | :type:`string`              | :value:`2016`                         |
+----------------------------+-----------------------------+---------------------------------------+
| Target Office version. Supported values: 2013, 2016, 2019, 2021                                  |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`keyfile`           | :type:`label`               | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| Strong name key file (.snk) for signing the assembly. Required for VSTO add-ins.                 |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`cert_file`         | :type:`label`               | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| Authenticode certificate (.pfx) for signing manifests. Optional but recommended for deployment.  |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`cert_password`     | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| Password for the certificate file.                                                               |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`install_url`       | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| ClickOnce installation URL for the deployment manifest.                                          |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`publisher`         | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| Publisher name for the deployment manifest.                                                      |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`data`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| Additional files to include as deployment dependencies.                                          |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`target_framework`  | :type:`string`              | :value:`net472`                       |
+----------------------------+-----------------------------+---------------------------------------+
| Target .NET Framework version. VSTO requires net472 or higher.                                   |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_vsto_addin(
      name = "MyExcelAddIn.dll",
      srcs = [
          "ThisAddIn.cs",
          "Ribbon1.cs",
          "Ribbon1.Designer.cs",
      ],
      resources = [
          ":Ribbon1.resx",
      ],
      office_app = "Excel",
      office_version = "2016",
      target_framework = "net472",
      keyfile = ":MyAddIn.snk",
      cert_file = ":certificate.pfx",
      cert_password = "your_password",
      install_url = "http://myserver/MyExcelAddIn/",
      publisher = "My Company",
  )

net_resx
~~~~~~~~

Builds a .NET Framework .resources file from a single .resx file.
Uses resgen.exe from the Windows SDK.

Providers
^^^^^^^^^

* DotnetResource_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
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

Example
^^^^^^^

.. code:: python

    net_resx(
        name = "Transform",
        src = "Transform.resx",
    )

net_resx_multi
~~~~~~~~~~~~~~

Builds .NET Framework .resources files from multiple .resx files (one for each).

Providers
^^^^^^^^^

* DotnetResource_

Attributes
^^^^^^^^^^

+-----------------------------+-----------------------------+---------------------------------------+
| **Name**                    | **Type**                    | **Default value**                     |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`name`               | :type:`string`              | |mandatory|                           |
+-----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                      |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`srcs`               | :type:`label_list`          | |mandatory|                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The source files to be embedded.                                                                  |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`identiferBase`      | :type:`string`              | :value:`""`                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The logical name for given resource is constructed from identiferBase + "." +                     |
| "directory.replace('/','.')" + "." + basename + ".resources". The resulting name is used          |
| to load the resource.                                                                             |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`fixedIdentifierBase`| :type:`string`              | :value:`""`                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The logical name for given resource is constructed from fixedIdentiferBase + "." +                |
| "." + basename + ".resources. The resulting name is used to load the resource.                    |
| Either identifierBase or fixedIdentifierBase must be specified                                    |
+-----------------------------+-----------------------------+---------------------------------------+

net_resource
~~~~~~~~~~~~

Wraps a resource file so it can be embedded into an assembly.

Providers
^^^^^^^^^

* DotnetResource_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`src`               | :type:`label`               | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The source to be embedded.                                                                       |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`identifer`         | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| The logical name for the resource; the name that is used to load the resource.                   |
| The default is the basename of the file name (no subfolder).                                     |
+----------------------------+-----------------------------+---------------------------------------+

net_resource_multi
~~~~~~~~~~~~~~~~~~

Wraps multiple resource files so they can be embedded into an assembly.

Providers
^^^^^^^^^

* DotnetResource_

Attributes
^^^^^^^^^^

+-----------------------------+-----------------------------+---------------------------------------+
| **Name**                    | **Type**                    | **Default value**                     |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`name`               | :type:`string`              | |mandatory|                           |
+-----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                      |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`srcs`               | :type:`label_list`          | |mandatory|                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The source files to be embedded.                                                                  |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`identiferBase`      | :type:`string`              | :value:`""`                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The logical name for given resource is constructed from identiferBase + "." +                     |
| "directory.replace('/','.')" + "." + filename. The resulting name is used to load                 |
| the resource.                                                                                     |
+-----------------------------+-----------------------------+---------------------------------------+
| :param:`fixedIdentifierBase`| :type:`string`              | :value:`""`                           |
+-----------------------------+-----------------------------+---------------------------------------+
| The logical name for given resource is constructed from fixedIdentiferBase + "." +                |
| "." + filename. The resulting name is used to load the resource.                                  |
| Either identifierBase or fixedIdentifierBase must be specified                                    |
+-----------------------------+-----------------------------+---------------------------------------+

net_import_library, net_import_binary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Imports an external .dll or .exe and transforms it into DotnetLibrary_ so it can be referenced
as a dependency by other rules. Often used with NuGet packages.

Providers
^^^^^^^^^

* DotnetLibrary_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The direct dependencies of this dll.                                                             |
| These may be net_library rules or compatible rules with the DotnetLibrary_ provider.             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`src`               | :type:`label`               | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The file to be transformed into DotnetLibrary_ provider                                          |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_import_library(
      name = "Newtonsoft.Json",
      src = "@newtonsoft.json//file:lib/net45/Newtonsoft.Json.dll",
      visibility = ["//visibility:public"],
  )

net_stdlib
~~~~~~~~~~

Imports a .NET Framework SDK assembly and transforms it into DotnetLibrary_ so it can be referenced
as a dependency by other rules. Used by //dotnet/stdlib.net/... packages.

Providers
^^^^^^^^^

* DotnetLibrary_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The direct dependencies of this dll.                                                             |
| These may be net_library rules or compatible rules with the DotnetLibrary_ provider.             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`data`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of additional files to include in the list of runfiles for compile assembly             |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`dll`               | :type:`label`               | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| The file to be transformed into DotnetLibrary_ provider. If empty then `name` is used.           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`stdlib_path`       | :type:`label`               | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| The stdlib_path to be used instead of looking for one in sdk by name. Providing the parameter    |
| speeds up the rule execution because the proper file needs not to be searched for within sdk     |
+----------------------------+-----------------------------+---------------------------------------+

net_libraryset
~~~~~~~~~~~~~~

Groups libraries into sets which may be used as a dependency.

Providers
^^^^^^^^^

* DotnetLibrary_

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`data`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of additional files to include in the list of runfiles for compiled assembly            |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`deps`              | :type:`label_list`          | :value:`None`                         |
+----------------------------+-----------------------------+---------------------------------------+
| The list of dependencies.                                                                        |
+----------------------------+-----------------------------+---------------------------------------+

net_gac
~~~~~~~

References an assembly from the Global Assembly Cache (GAC).

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`assembly`          | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The assembly name (e.g., "System.Web")                                                           |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`version`           | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The assembly version (e.g., "4.0.0.0")                                                           |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_gac(
      name = "system_web",
      assembly = "System.Web",
      version = "4.0.0.0",
  )

net_com_library
~~~~~~~~~~~~~~~

Imports a COM type library and generates an interop assembly using tlbimp.exe.

Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+---------------------------------------+
| **Name**                   | **Type**                    | **Default value**                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| A unique name for this rule.                                                                     |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`src`               | :type:`label`               | |mandatory|                           |
+----------------------------+-----------------------------+---------------------------------------+
| The COM type library file (.tlb or .dll)                                                         |
+----------------------------+-----------------------------+---------------------------------------+
| :param:`namespace`         | :type:`string`              | :value:`""`                           |
+----------------------------+-----------------------------+---------------------------------------+
| Optional namespace for the generated interop assembly                                            |
+----------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: python

  net_com_library(
      name = "MyComLib",
      src = "MyComLib.tlb",
      namespace = "MyCompany.Interop.MyComLib",
  )
