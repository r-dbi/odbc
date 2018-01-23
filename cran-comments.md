This release fixes an upstream due to a change in the latest version of dbplyr
(1.2.0), which is the reason odbc needs an update so soon after the previous
one.

## Test environments
* local OS X install, R 3.4.3
* ubuntu 14.04 (on travis-ci), R 3.4.3
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 0 note

## Downstream dependencies

I ran `R CMD check` on the 2 reverse dependencies
(https://github.com/r-dbi/odbc/tree/master/revdep#readme). There were no errors
from these changes.
