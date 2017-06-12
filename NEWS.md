# odbc 1.0.1.9000

* Time objects are converted to and from `hms` objects.

* 64 bit integers are converted to and from `bit64` objects.

* Adding support for Impala data types (@edgararuiz)

* Adding support for Hive data types (#38 @edgararuiz)

# odbc 1.0.1

* Fixes for the CRAN build machines
  - Do not force c++14 on windows
  - Turn off database tests on CRAN, as I think they will be difficult to debug even if databases are supported.

* Added a `NEWS.md` file to track changes to the package.

# odbc 1.0.0

* Initial odbc release
