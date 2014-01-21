# Synopsis

A very small C++ wrapper for the native C ODBC API. Please see the [online documentation](http://lexicalunit.github.com/nanodbc/) for user information, example usage, propaganda, and detailed source level documentation.

# Building

You don't necessarily need to build nanodbc, as you can just drop the header and implementation files into your project. However I have provided [CMake](www.cmake.org/) files which can be used to build a shared library object, or build and run the included unit tests. The CMake files will also support out of source builds.

Unit tests are built using [Boost.Test](www.boost.org/doc/libs/release/libs/test/) and therefore require Boost be installed. In order to build the tests you will also need to have either unixODBC or iODBC installed and discoverable by CMake. This is easy on OS X (for example) where you can just use [Homebrew](brew.sh/‎) to install unixodbc with ```brew install unixodbc```, or simply use the system provided iODBC if you have OS X prior to 10.9. Finally, the unit tests attempt to connect to a [SQLite](www.sqlite.org/‎) database, so you will need to have that installed as well.

## Example Build Process

```bash
cd path/to/nanodbc/repository
mkdir build
cd build
cmake ..
make # creates shared library
make nanodbc # creates shared library
make example # builds example program
make tests # builds unit tests
make test # runs unit tests
make check # builds and then runs unit tests
make install # installs nanodbc.h and shared library
```
