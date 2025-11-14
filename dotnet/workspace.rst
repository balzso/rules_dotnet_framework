.NET Framework workspace rules
================================

.. note::
   This documentation is adapted from the original `rules_dotnet <https://github.com/bazelbuild/rules_dotnet>`_ project (commit d672bdb).
   This fork focuses exclusively on .NET Framework 4.7-4.7.2 support on Windows.

.. _dotnet_library: core.rst#dotnet_library
.. _toolchains: toolchains.rst
.. _dotnet_register_toolchains: toolchains.rst#dotnet_register_toolchains
.. _dotnet_toolchain: toolchains.rst#dotnet_toolchain
.. _http_archive: https://docs.bazel.build/versions/master/be/workspace.html#http_archive
.. _git_repository: https://docs.bazel.build/versions/master/be/workspace.html#git_repository
.. _nested workspaces: https://bazel.build/designs/2016/09/19/recursive-ws-parsing.html
.. _dotnet_import_library: core.rst#dotnet_import_library
.. _nuget2bazel: /tools/nuget2bazel/README.rst

.. role:: param(literal)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**

Workspace rules are either repository rules, or macros that are intended to be used from the
WORKSPACE file.

See also the toolchains_ rules, which contains the dotnet_register_toolchains_
workspace rule.

.. contents:: :depth: 1

-----


.. _dotnet_repositories:

dotnet_repositories
~~~~~~~~~~~~~~~~~~~

Fetches remote repositories required before loading other rules_dotnet files. It fetches basic dependencies.

For example: bazel_skylib is loaded.

dotnet_repositories_nugets
~~~~~~~~~~~~~~~~~~~~~~~~~~

Fetches nuget repositories required by rules.


dotnet_nuget
~~~~~~~~~~~~

A simple repository rule to download and extract nuget package. Using dotnet_nuget_new_ is usually
a better idea.


Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+-----------------------------------------------+
| **Name**                   | **Type**                    | **Default value**                             |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| A unique name for this rule.                                                                             |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`source`            | :type:`string`              | :value:`https://www.nuget.org/api/v2/package` |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget base url for downloading the package. The final url is in the format                           |
| {source}/{package}/{version}.                                                                            |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`package`           | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package name                                                                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`version`           | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package version.                                                                               |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`sha256`            | :type:`string`              | :value:`None`                                 |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package sha256 digest.                                                                         |
+----------------------------+-----------------------------+-----------------------------------------------+


dotnet_nuget_new
~~~~~~~~~~~~~~~~

Repository rule to download and extract nuget package. Usually used with dotnet_import_library_.


Attributes
^^^^^^^^^^

+----------------------------+-----------------------------+-----------------------------------------------+
| **Name**                   | **Type**                    | **Default value**                             |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`name`              | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| A unique name for this rule.                                                                             |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`source`            | :type:`string`              | :value:`https://www.nuget.org/api/v2/package` |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget base url for downloading the package. The final url is in the format                           |
| {source}/{package}/{version}.                                                                            |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`package`           | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package name                                                                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`version`           | :type:`string`              | |mandatory|                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package version.                                                                               |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`sha256`            | :type:`string`              | :value:`None`                                 |
+----------------------------+-----------------------------+-----------------------------------------------+
| The nuget package sha256 digest.                                                                         |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`build_file`        | :type:`label`               | :value:`None`                                 |
+----------------------------+-----------------------------+-----------------------------------------------+
| The build file to link into downloaded nuget package.                                                    |
+----------------------------+-----------------------------+-----------------------------------------------+
| :param:`build_file_content`| :type:`string`              | :value:`""`                                   |
+----------------------------+-----------------------------+-----------------------------------------------+
| The build file content to put into downloaded nuget package.                                             |
+----------------------------+-----------------------------+-----------------------------------------------+

Example
^^^^^^^

.. code:: python

    dotnet_nuget_new(
        name = "npgsql",
        package = "Npgsql",
        version = "3.2.7",
        sha256 = "fa3e0cfbb2caa9946d2ce3d8174031a06320aad2c9e69a60f7739b9ddf19f172",
        build_file_content = """
    package(default_visibility = [ "//visibility:public" ])
    load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_import_library")

    net_import_library(
        name = "npgsqllib",
        src = "lib/net451/Npgsql.dll"
    )
        """
    )

nuget_package
~~~~~~~~~~~~~

Repository rule to download and extract nuget package. The rule is usually generated by nuget2bazel_ tool.


Attributes
^^^^^^^^^^

+----------------------------+------------------------------+------------------------------------------------+
| **Name**                   | **Type**                     | **Default value**                              |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`name`              | :type:`string`               | |mandatory|                                    |
+----------------------------+------------------------------+------------------------------------------------+
| A unique name for this rule.                                                                               |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`source`            | :type:`list of string`       | :value:`[https://www.nuget.org/api/v2/package`]|
+----------------------------+------------------------------+------------------------------------------------+
| The nuget base url for downloading the package. The final url is in the format                             |
| {source}/{package}/{version}.                                                                              |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`package`           | :type:`string`               | |mandatory|                                    |
+----------------------------+------------------------------+------------------------------------------------+
| The nuget package name                                                                                     |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`version`           | :type:`string`               | |mandatory|                                    |
+----------------------------+------------------------------+------------------------------------------------+
| The nuget package version.                                                                                 |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`sha256`            | :type:`string`               | :value:`None`                                  |
+----------------------------+------------------------------+------------------------------------------------+
| The nuget package sha256 digest.                                                                           |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`net_lib`           | :type:`string`               | :value:`None`                                  |
+----------------------------+------------------------------+------------------------------------------------+
| The path to .NET Framework assembly within the nuget package (e.g., "lib/net472/Package.dll")             |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`net_tool`          | :type:`string`               | :value:`None`                                  |
+----------------------------+------------------------------+------------------------------------------------+
| The path to .NET Framework tool assembly within the nuget package (tools subdirectory)                     |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`net_deps`          | :type:`list of DotnetLibrary`| :value:`None`                                  |
+----------------------------+------------------------------+------------------------------------------------+
| The list of the dependencies of the package (.NET Framework)                                               |
+----------------------------+------------------------------+------------------------------------------------+
| :param:`net_files`         | :type:`list of string`       | :value:`None`                                  |
+----------------------------+------------------------------+------------------------------------------------+
| The list of additional files within the package to be used as runfiles (necessary to run)                  |
+----------------------------+------------------------------+------------------------------------------------+


Example
^^^^^^^

.. code:: python

    nuget_package(
        name = "newtonsoft.json",
        package = "Newtonsoft.Json",
        version = "12.0.3",
        sha256 = "17e5e4c8c06d59f150b1e1ab9098a3eaa261c787fabc118e1882bdad32511c90",
        net_lib = "lib/net45/Newtonsoft.Json.dll",
        net_deps = [
            "@io_bazel_rules_dotnet//dotnet/stdlib.net/net472:System.dll",
            "@io_bazel_rules_dotnet//dotnet/stdlib.net/net472:System.Core.dll",
            "@io_bazel_rules_dotnet//dotnet/stdlib.net/net472:System.Xml.dll",
        ],
        net_files = [
            "lib/net45/Newtonsoft.Json.dll",
            "lib/net45/Newtonsoft.Json.xml",
        ],
    )

Using with nuget2bazel
^^^^^^^^^^^^^^^^^^^^^^

The recommended way to manage NuGet packages is to use the nuget2bazel_ tool, which automatically
generates nuget_package rules with correct dependencies:

.. code:: bash

    # Add a package
    bazel run //tools/nuget2bazel:nuget2bazel.exe -- add -p . Newtonsoft.Json 12.0.3

    # Delete a package
    bazel run //tools/nuget2bazel:nuget2bazel.exe -- delete -p . Newtonsoft.Json

This will automatically:
- Download the NuGet package
- Calculate the SHA256 hash
- Determine the correct .NET Framework library path
- Identify dependencies
- Generate the nuget_package rule in your WORKSPACE or .bzl file
