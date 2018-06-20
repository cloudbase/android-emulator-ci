About
=====

This repository contains scripts that are used for provinding a CI test
infrastructure, covering Android Emulator, with a specific interest in the
WHPX (Windows Hypervisor Platform) accelerator.

While the main goal is automating Android Emulator tests, those jobs can also
be used to set up development/testing environments really quick, in less than
10 minutes.

Workflow
========
For each test run, we're rebuilding the emulator (currently using the tip of
the master dev branch, soon we'll add support for testing Gerrit patches or
certain branches/tags).

We're currently relying on OpenStack to provision VMs that are used for
building the emulator and running the emulator tests.

This basically means that emulator instances are running nested, for which
reason the underlying compute host must use Windows Server 2016 RS4 (1803),
while the Windows guests will use Windows 10 RS4 or newer.

To speed things up, we're building the emulator while the Windows VM is
provisioned and the Android SDK gets installed. The AOSP tree is cached on the
builder VM image, also containing ccache output from a previous run.

This way, we get a test environment up in less than 15 minutes (which can
also be used for dev/testing purposes). We also support reusing previous
builds, in which case it takes less than 10 minutes to spin up the
environment.

The logs, test results along with build packages are pushed to a configured
log server.

The top level job [scripts](jobs) are executed on a Linux host (in our
case, through Jenkins), which in turn invoke commands on the Windows VM
through WinRM.

Each job will use a state dir at a configured location, containing various
logs, SMB share mounts, as well as a file storing various information
about the job (e.g. VM IDs and IPs).

If configured to do so, various stages may be omitted (e.g. VM cleanup,
useful for debugging purposes).

Performed tests
===============
We're running the in-tree android emulator unit tests, along with the
integration tests from
[adt-infra](https://android.googlesource.com/platform/external/adt-infra/emu_tests).

Some unit tests that are known to be crashing or hanging are run isolated
so that this won't impact the rest of the unit test suite.

Because of the same reason, we're using fine grained timeouts, ensuring that
even if something hangs, we'll get as much coverage as possible from a single
test run.

The test results will include XMLs as well as raw console output (from the
test themselves, as well as emulator instances).

Each test run will stream the results using the
[subunit](https://github.com/testing-cabal/subunit/) format, which are then
aggregated and converted to html.

The subunit v2 test streaming protocol has some major benefits, such as:
* binary format, uses 4K sized event packets, doesn't get corrupted
  that easily
* considerable number of parsers
* easy to aggregate results
* multiple runners can use the same output file without corrupting it
* we don't lose test results if the runner gets killed (e.g. after
  a timeout) or crashes.

Configuration
=============
The top level job [configuration](jobs/job.rc) provides some default config
values that can easily be overriden through environment variables. The same
applies to the builder [config](build_host/build.rc).

The Windows scripts also have a [config](test_host/global_config.ps1), but
it's pretty much hardcoded. Using environment variables there would only
make sense if used outside the scope of the CI automation.

Authentication
==============
OpenStack access information must be provided through environment variables,
automatically getting picked up by the OpenStack clients.

Various SSH keys and certificates stored at configured locations are used
when accessing the VMs and log server.

Logging
=======
The bash script logs are extremely verbose, having xtrace enabled. Each
of those scripts will also write a summary log.
