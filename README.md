# Synopsis

[![Build Status](https://travis-ci.org/lexicalunit/nanodbc.svg?branch=master)](https://travis-ci.org/lexicalunit/nanodbc)

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
cmake [Build Options] ..
make # creates shared library
make nanodbc # creates shared library
make tests # builds the unit tests
make test # runs the unit tests
make check # builds and then runs unit tests
make install # installs nanodbc.h and shared library
```

## Build Options

The following build options are available via CMake. If you are not using CMake to build nanodbc, you will need to set the corresponding `-D` compile define flags yourself. You will need to configure your build to use [boost](http://www.boost.org/) if you want to use the `NANODBC_USE_BOOST_CONVERT` option.

| CMake&nbsp;Option                 | Possible&nbsp;Values | Default     | Details |
| --------------------------------  | -------------------- | ----------- | ------- |
| `‑DNANODBC_USE_UNICODE=...`       | `OFF` or `ON`        | `OFF`       | Enables full unicode support. `nanodbc::string` becomes `std::wstring`. |
| `‑DNANODBC_HANDLE_NODATA_BUG=...` | `OFF` or `ON`        | `OFF`       | Provided to resolve issue [#33](https://github.com/lexicalunit/nanodbc/issues/33), details [in this commit](https://github.com/lexicalunit/nanodbc/commit/918d73cdf12d5903098381344eecde8e7d5d896e). |
| `‑DNANODBC_USE_BOOST_CONVERT=...` | `OFF` or `ON`        | `OFF`       | Provided as workaround to issue [#44](https://github.com/lexicalunit/nanodbc/issues/44). |
| `‑DNANODBC_STATIC=...`            | `OFF` or `ON`        | `OFF`       | Enables building a static library, otherwise the build process produces a shared library. |
| `‑DNANODBC_INSTALL=...`           | `OFF` or `ON`        | `ON`        | Enables install target. |
| `‑DNANODBC_TEST=...`              | `OFF` or `ON`        | `ON`        | Enables tests target (alias `check`). |
| `‑DNANODBC_ODBC_VERSION=...`      | `SQL_OV_ODBC3[...]`  | See Details | **[Optional]** Sets the ODBC version macro for nanodbc to use. Default is `SQL_OV_ODBC3_80` if available, otherwise `SQL_OV_ODBC3`. |

# Contributing

## Publish and Release Process

Once your local `master` branch is ready for publishing (i.e. [semantic versioning](http://semver.org/)), use the `scripts/publish.sh` script. This script bumps the major, minor, or patch version, then updates the repository's `VERSION` file, adds a "Preparing" commit, and creates git tags appropriately. For example to make a minor update you would run `./scripts/publish.sh minor`.

To do this manually instead, use the following steps &mdash; for example a minor update from `2.9.x` to `2.10.0`:

1. `echo "2.10.0" > VERSION`
2. `git add VERSION`
3. `git commit -m "Preparing 2.10.0 release."`
4. `git tag -f "v2.10.0"`
5. `git push -f origin "v2.10.0"`

Release nanodbc with the `scripts/release.sh` script. All this script does is push out the `master` branch to the `release` branch, indicating that a new stable version of nanodbc exists. To do so manually, execute `git push -f origin master:release`.

## Source Level Documentation

Source level documentation provided via [GitHub's gh-pages](https://help.github.com/articles/what-are-github-pages/) is available at [nanodbc.lexicalunit.com](http://lexicalunit.github.io/nanodbc/). To re-build and update it, preform the following steps from the root directory of the repository:

1. `git clone -b gh-pages git@github.com:lexicalunit/nanodbc.git doc` (necessary the first time, not subsequently)
2. `cd doc`
3. `make` Generates updated documentation locally.
4. `make commit` Commits and pushes new local documentation up to github.

Building documentation and gh-pages requires the use of [Doxygen](www.doxygen.org) and [jekyll](https://jekyllrb.com/). See the `Makefile` on the `gh-pages` branch of nanodbc for more details.

## Future work

- Update codebase to use more C++14 idioms and patterns.
- Write more tests with the goal to have much higher code coverage.
- More tests for a large variety of drivers. Include performance tests.
- Clean up `bind_*` family of functions, reduce any duplication.
- Improve documentation: The main website and API docs should be more responsive.
- Provide more examples in documentation, more details, and point out any gotchas.
- Refactor code to remove the need for the `NANODBC_HANDLE_NODATA_BUG` option.
- Fill out the Contributing section of this readme with more helpful information. Maybe a getting started section?
