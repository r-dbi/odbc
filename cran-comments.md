Trying again - I think we should now be passing on M1mac. Sorry for the multiple attempts here but something is configured in an unexpected way on that system and we're having a hard time replicating locally.

## R CMD check results

Recent MacOS builds trigger the NOTE "installed size is 11.0Mb." MacOS builds include all debug symbols and CRAN policy doesn't permit building without them.

## revdepcheck results

We checked 35 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
