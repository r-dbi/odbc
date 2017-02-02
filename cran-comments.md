## Test environments
* local OS X install, R 3.3.0.
* Ubuntu 12.04 (on travis-ci), R-oldrel, R-release, R-devel
* Windows Server 2012 R2 (x64), R 3.3.0
* Rhub
  * Windows Server 2008 R2 SP1, R-devel, 32/64 bit
  * Debian Linux, R-devel, GCC ASAN/UBSAN
  * Fedora Linux, R-devel, clang, gfortran
  * Ubuntu Linux 16.04 LTS, R-release, GCC

While this package does rely on an ODBC driver manager (such as unixODBC) to be
installed I believe this package should build on the CRAN machines without
additional configuration.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

* Possibly mis-spelled words in DESCRIPTION:
  ODBC (2:19, 10:57)
ODBC is a standard acronym.

* Found the following (possibly) invalid URLs:
  URL: https://cran.r-project.org/package=odbc
    From: README.md
    Status: 404
    Message: Not Found
This URL will become valid once the package is accepted on CRAN.

## Reverse dependencies

This is a new release, so there are no reverse dependencies.
