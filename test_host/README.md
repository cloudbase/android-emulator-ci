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
* jdk 8 (10 doesn't work)
    * make sure to add a firewall exception

Test requirements
-----------------
* Emulator unit tests package
* Python (currently using 2.7, not sure if 3.x is supported). Make sure that
  the Python and Python\Scripts paths are added to %PATH%
   * pip
