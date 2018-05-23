About
=====

This repository contains scripts that will be used for provinding a CI test
infrastructure, covering Android Emulator, with a specific interest in the
WHPX (Windows Hypervisor Platform) accelerator.

Requirements
============

Sdk requirements
---------------------
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
