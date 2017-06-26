This release fixes the failures on CRANs' Solaris build machines by requiring
GNU make and using $(MAKE) macros.

## Test environments
* local OS X install, R 3.3.2
* ubuntu 12.04 (on travis-ci), R-release, R-devel
* Rhub, with rhub::check_for_cran()

## R CMD check results

0 errors | 0 warnings | 1 note

* Possibly mis-spelled words in DESCRIPTION:
  ODBC (2:19, 10:57)
ODBC is a standard acronym.

## Reverse dependencies

I ran `R CMD check` on all 2 reverse dependencies (https://github.com/rstats-db/odbc/tree/master/revdep).

There were no issues found.
