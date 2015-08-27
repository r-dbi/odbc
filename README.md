# Synopsis

A small C++ wrapper for the native C ODBC API. Please see the [online documentation](http://lexicalunit.github.com/nanodbc/) for user information, example usage, propaganda, and detailed source level documentation.

# Versions

| Tag&nbsp;or&nbsp;Branch | Description |
| ---:|:--- |
| `master`  | Contains the latest development code, not yet ready for release. |
| `release` | Always pegged to the most recent stable release. |
| `v2.0.0`  | Targets C++14+. All future development will build upon this version. |
| `v1.0.0`  | Supports C++03 and optionally C++11. *There is no longer any support for this version.* |

# Building

Nanodbc is intentionally small enough that you can drag and drop the header and implementation files into your project and run with it. For those that want it, I have also provided [CMake](http://www.cmake.org/) files which build a shared library object, or build and run the included unit tests. The CMake files will also support out of source builds.

Building unit tests requires [Boost.Test](http://www.boost.org/doc/libs/release/libs/test/). To build the tests you will also need to have either unixODBC or iODBC installed and discoverable by CMake. This is easy on OS X where you can use [Homebrew](http://brew.sh/) to install unixODBC with `brew install unixodbc`, or use the system provided iODBC if you have OS X 10.9 or earlier. Also note that you can install Boost via Homebrew as well, which is super convenient!

The unit tests attempt to connect to a [SQLite](https://www.sqlite.org/) database, so you will have to have that and a SQLite ODBC driver installed. At the time of this writing, there happens to be a nice [SQLite ODBC driver](http://www.ch-werner.de/sqliteodbc/) available from Christian Werner's website. The tests expect to find a data source named `sqlite`. For example, your `odbcinst.ini` file on OS X will have a section like the following.

```
[sqlite]
Description             = SQLite ODBC
Driver                  = /usr/lib/libsqlite3odbc-0.93.dylib
Setup                   = /usr/lib/libsqlite3odbc-0.93.dylib
Threading               = 2
```

## Example Build Process

It's most convenient to create a build directory for an out of source build, but this isn't required. After you've used cmake to generate your Makefiles, `make nanodbc` will build your shared object. `make check` will build and run the unit tests. If the unit tests fail, please don't hesitate to report it by creating an issue [with your detailed test log](http://stackoverflow.com/questions/5709914/using-cmake-how-do-i-get-verbose-output-from-ctest)! You can also install nanodbc to your system using `make install`.

```shell
cd path/to/nanodbc/repository
mkdir build
cd build
cmake .. [Build Options]
make # creates shared library
make nanodbc # creates shared library
make tests # builds the unit tests
make test # runs the unit tests
make check # builds and then runs unit tests
make install # installs nanodbc.h and shared library
```

## Build Options

The following build options are available via CMake. If you are not using CMake to build nanodbc, you will need to set the corresponding `-D` compile define flags yourself. You will need to configure your build to use [boost](http://www.boost.org/) if you want to use the `NANODBC_USE_BOOST_CONVERT` option.

| CMake Option                     | Description |
| -------------------------------- | ----------- |
| `‑DNANODBC_USE_UNICODE=ON`       | Enables full unicode support. `nanodbc::string` becomes `std::wstring`. |
| `‑DNANODBC_HANDLE_NODATA_BUG=ON` | Provided to resolve issue [#33](https://github.com/lexicalunit/nanodbc/issues/33), details [in this commit](https://github.com/lexicalunit/nanodbc/commit/918d73cdf12d5903098381344eecde8e7d5d896e). |
| `‑DNANODBC_USE_BOOST_CONVERT=ON` | Provided as workaround to issue [#44](https://github.com/lexicalunit/nanodbc/issues/44). |

# Future work

- Update codebase to use more C++14 idioms and patterns.
- More tests for a large variety of drivers. Include performance tests.
- Clean up `bind_*` family of functions, reduce any duplication.
- Improve documentation: The main website and API docs should be more responsive.
- Refactor code to remove the need for the `NANODBC_HANDLE_NODATA_BUG` option.
