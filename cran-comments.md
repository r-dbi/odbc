## R CMD check results

Recent MacOS builds have trigger the NOTE "installed size is 10.8Mb." MacOS builds include all debug symbols and CRAN policy doesn't permit building without them.

"Additional issues" checks on M1 Mac surface a number of new warnings related to GCC SQL/ODBC deprecations resulting from `sys-iodbc` headers overwriting `unixodbc` headers in `R-macos/recipes` (see https://github.com/R-macos/recipes/issues/41 and linked issues).

## revdepcheck results

We checked 32 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages

