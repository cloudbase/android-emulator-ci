Installing
==========

Here's the install sequence:
* check_prerequisites.ps1
* install_sdk.ps1
* install_emulator.ps1

The first stages should be run while waiting for the emulator to build.

Requirements
============

Sdk requirements
----------------
* Android sdk archive
* Android emulator archive
* msys
* jre 1.8 (1.10 doesn't work)

Test requirements
-----------------
* Emulator unit tests package
* Python (currently using 2.7, not sure if 3.x is supported). Make sure that
  the Python and Python\Scripts paths are added to %PATH%
   * pip
