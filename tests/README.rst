Dotnet rules test suite
=======================

Main test areas
---------------

.. Child list start

* `.NET Framework rules examples <examples/README.rst>`_
* `.NET Framework rules tests <core/README.rst>`_

.. Child list end

Adding a new test
-----------------

All tests in the test suite are expected to obey certain rules.

They must be documented
    Each test folder must contain a README.rst that documents the area of
    reponsability for the folder. That README must have a section with
    the same name as each of the test rules that documents exactly what the
    test is supposed to be checking for.
    If the test is in response to a previous issue, the documentation must
    also link to the issue being addressed.

Test one thing at a time
    Each test should have a clear and specific responsability, and it should be
    as tightly targeted as possible.
    Prefer writing multiple tests in a single folder to a single test that
    excercises multiple things.

They must be turned on
    Test that do not run by default on the CI machines are not much use,
    especially as it's often the only way changes get tested in environments
    that are not the one they are authored on, and the rules are very sensitive
    to platform specific variations.

They must not be flakey
    We will generally just delete tests that flake, and if features cannot be
    tested without flakes we will probably delete the feature as well.

They must work on Windows
    This fork is Windows-only. All tests must run on Windows with .NET Framework 4.7+
    installed. Tests do not need to run on macOS or Linux.

They must be as fast as possible
    Some tests need to be large and expensive, but most do not. In particular,
    downloading large external dependancies to perform a small unit test is not
    ok, prefer creating a small local replication of the problem instead.
    Anything that requires external dependancies beyond those of the rules
    belongs in the integration tests.