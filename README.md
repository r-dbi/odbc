# Synopsis

A very small C++ wrapper for the native C ODBC API. Please see the [online documentation](http://lexicalunit.github.com/nanodbc/) for user information, example usage, propaganda, and detailed source level documentation.

# Building

You don't necessarily need to build nanodbc, as you can just drop the header and implementation files into your project. However I have provided [CMake](www.cmake.org/) files which can be used to build a shared library object, or build and run the included unit tests. The CMake files will also support out of source builds.

Unit tests are built using [Boost.Test](www.boost.org/doc/libs/release/libs/test/) and therefore require Boost be installed. In order to build the tests you will also need to have either unixODBC or iODBC installed and discoverable by CMake. This is easy on OS X (for example) where you can just use [Homebrew](brew.sh/‎) to install unixODBC with ```brew install unixodbc```, or simply use the system provided iODBC if you have OS X prior to 10.9. Also note that you can install Boost via Homebrew as well, which is very convenient!

Finally, the unit tests attempt to connect to a [SQLite](www.sqlite.org/‎) database, so you will have to have that and a SQLite ODBC driver installed. At the time of this writing, there happens to be a nice [SQLite ODBC driver](http://www.ch-werner.de/sqliteodbc/) available from Christian Werner's website. The tests expect to find a data source named ```sqlite```. So for example, your ```odbcinst.ini``` file on OS X might have a section similar to the following.

```
[sqlite]
Description             = SQLite ODBC Driver
Driver                  = /usr/lib/libsqlite3odbc-0.93.dylib
Setup                   = /usr/lib/libsqlite3odbc-0.93.dylib
Threading               = 2
```	

## Example Build Process

It's most convenient to create a build directory for an out of source build, but this isn't required. After you've used cmake to generate your Makefiles, you probably only really need to be aware of ```make nanodbc``` which will build your shared object, or ```make check``` which will build and run the unit tests. If the unit tests fail, please don't hesitate to report it by creating an issue including a log of the output you're getting! You may also want to install nanodbc to your system using ```make install```.

```bash
cd path/to/nanodbc/repository
mkdir build
cd build
cmake .. [-DNANODBC_USE_CPP11=ON] [-DNANODBC_USE_UNICODE=ON]
make # creates shared library
make nanodbc # creates shared library
make example # builds example program
make tests # only builds the unit tests
make test # only runs the unit tests
make check # builds and then runs unit tests
make install # installs nanodbc.h and shared library
```
