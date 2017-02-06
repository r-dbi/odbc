## Test environments
* local OS X install, R 3.3.0.
* Ubuntu 12.04 (on travis-ci), R-oldrel, R-release, R-devel
* Windows Server 2012 R2 (x64), R 3.3.0
* Rhub
  * Windows Server 2008 R2 SP1, R-devel, 32/64 bit
  * Debian Linux, R-devel, GCC ASAN/UBSAN
  * Fedora Linux, R-devel, clang, gfortran
  * Ubuntu Linux 16.04 LTS, R-release, GCC


This release fixes check errors with odbc 1.0.0 on the fedora and windows CRAN build machines.

The failure on MacOS looks to be because the build machine has the homebrew
package manager installed, but does _not_ have the `unixodbc` homebrew package
installed. Either `brew install unixodbc` can be run on the build machine, or
the unixODBC package can be compiled manually and installed elsewhere. If the
`odbc_config` program is available on the `PATH` it will be queried for the
appropriate include and library directories appropriately. Otherwise the
locations can be specified manually with `R CMD INSTALL --configure-vars='INCLUDE_DIR=... LIB_DIR=...'`.

## R CMD check results

0 errors | 0 warnings | 1 note

* Possibly mis-spelled words in DESCRIPTION:
  ODBC (2:19, 10:57)
ODBC is a standard acronym.

## Reverse dependencies

This is a new release, so there are no reverse dependencies.
