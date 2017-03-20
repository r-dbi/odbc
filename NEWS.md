# odbc 1.0.1

* Added support for Hive data types (#38, @edgararuiz) 
* Fixes for the CRAN build machines
  - Do not force c++14 on windows
  - Turn off database tests on CRAN, as I think they will be difficult to debug even if databases are supported.

* Added a `NEWS.md` file to track changes to the package.

# odbc 1.0.0

* Initial odbc release
