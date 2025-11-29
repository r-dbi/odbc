# Installing and Configuring Drivers

This vignette outlines how to install common ODBC drivers and configure
them with a driver manager.

## Installation

For Unix and MacOS, ODBC drivers should be compiled against
[unixODBC](https://www.unixodbc.org/). Drivers compiled against
[iODBC](https://www.iodbc.org/) *may* also work, but are not fully
supported.

After installation of the driver manager and driver, you will have to
register the driver in a [odbcinst.ini](#dsn-configuration-files) file
for it to appear in
[`odbc::odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md).

### Windows

Windows is bundled with ODBC libraries. However, drivers for each
database need to be installed separately. Windows ODBC drivers typically
include an installer that needs to be run and will install the driver to
the proper locations.

### MacOS

[homebrew](https://brew.sh/) can be used to easily install database
drivers on MacOS.

The UnixODBC driver manager is required for all databases:

``` shell
## Install the unixODBC library
brew install unixodbc
```

Most common database drivers can be installed with homebrew. Some
drivers are only available from the database vendor.

``` shell
## Microsoft SQL Server ODBC drivers
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install msodbcsql17 mssql-tools

## SQL Server ODBC drivers (Free TDS)
brew install freetds

## PostgreSQL ODBC drivers
brew install psqlodbc

## MySQL ODBC drivers (and database)
brew install mysql
brew install mariadb-connector-odbc

## SQLite ODBC drivers
brew install sqliteodbc
```

Some driver installations will not automatically configure the driver
with the driver manager. See the [“Connecting to a
Database”](#connecting) section below to learn more about configuring
drivers and data sources.

### Linux - Debian / Ubuntu

[apt-get](https://wiki.debian.org/Apt) can be used to easily install
database drivers on Linux distributions which support it, such as Debian
and Ubuntu.

The UnixODBC driver manager is required for all databases:

``` shell
## Install the unixODBC library
apt-get install unixodbc unixodbc-dev
```

For SQL Server on Linux it is recommended you use the [Microsoft
Drivers](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#ubuntu18).
The code below will install some common drivers:

``` shell
## SQL Server ODBC Drivers (Free TDS)
apt-get install tdsodbc

## PostgreSQL ODBC ODBC Driversz
apt-get install odbc-postgresql

## MySQL ODBC Drivers
apt-get install libmyodbc

## SQLite ODBC Drivers
apt-get install libsqliteodbc
```

## Driver configuration

On Windows, driver config is managed by the operating system, and you
don’t generally need to edit any configuration files directly. On MacOS
and Linux, however, the driver config is managed by unixODBC, and
depending on how the driver is installed, it may or may not be
automatically configured.

You can see which drivers are configured by running
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md).
If the driver you want is not installed, you will need to edit
`odbcinst.ini`. You can use `odbcinst -j` (provided by unixODBC) to find
out where this file lives.

The basic form of this file is something like this:

``` ini
[PostgreSQL Driver]
Driver          = /usr/local/lib/psqlodbcw.so

[SQLite Driver]
Driver          = /usr/local/lib/libsqlite3odbc.dylib
```

i.e., a mapping between driver names, and the location of the driver
file. The driver name is what you pass to
[`odbc::odbc()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
when you connect, e,g:

``` r
library(DBI)
con1 <- dbConnect(odbc::odbc(), driver = "PostgreSQL Driver")
con2 <- dbConnect(odbc::odbc(), driver = "SQLite Driver")
```

If installing the driver did not automatically update this file, you’ll
need to update it yourself. You’ll need to figure out where the driver
library was installed, using something like `brew list {drivername}` or
`dpkg-query -L {drivername}`.

## Data source configuration

It’s also possible to configure named data sources, so instead of typing
this:

``` r
library(DBI)
con <- dbConnect(
  odbc::odbc(),
  driver = "PostgreSQL Driver",
  database = "test_db",
  username = "postgres",
  password = Sys.getenv("PASSWORD"),
  host = "localhost",
  port = 5432
)
```

You can type:

``` r
con <- dbConnect(odbc::odbc(), dsn = "test_db")
```

On Windows, you can set up a data source by using the [ODBC Data Source
Administrator](https://learn.microsoft.com/en-us/sql/odbc/admin/odbc-data-source-administrator)
application is used to manage ODBC data sources on Windows. On Linux and
Mac, you’ll need to edit `odbc.ini` (again finding the location with
`odbcinst -j`). Each data source is defined in a separate section
(defined by `[name]`\]), with each paramter going on its own line, e.g.:

``` ini
[test_db]
driver     = PostgreSQL Driver
database   = test_db
username   = postgres
password   = password
host       = localhost
port       = 5432
```

The `driver` entry represents the name of the driver defined in
`odbcinst.ini`. You can see all currently defined data sources by
running
[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md).

## Debugging driver and data source configurations

The odbc package may have trouble locating your driver and data source
configurations. If you find that
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
and
[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
report no configurations, check the output of
[`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
next. While
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
and
[`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
interface with the unixodbc driver manager through nanodbc—the tool that
the odbc package uses to interface with the ODBC
API—[`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
interfaces with unixODBC directly.
[`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
will show where unixODBC is looking for your configurations.

- If the files listed in
  [`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  are at a location other than where you’ve configured drivers and data
  sources, either 1) configure the listed files as instructed above,
  or 2) change the folder where ODBC should look for configurations
  using the `ODBCSYSINI` environmental variable. See [the following
  section](#odbcsysini) on setting `ODBCSYSINI`.

- If the files listed in
  [`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  are where you expected them to be and appear complete, the odbc
  package may have had trouble interfacing with the unixODBC driver
  manager through nanodbc. To remedy this, first run
  `dirname(odbcListConfig()[1])` and note its output. Then, follow the
  instructions in [the section below](#odbcsysini), replacing
  `"some/folder"` with the noted output. If this doesn’t resolve the
  issue, try to build the odbc package from source, e.g. with
  `devtools::install_github("r-dbi/odbc")`.

### Setting `ODBCSYSINI`

The `ODBCSYSINI` environmental variable controls the path where unixODBC
and the odbc package will look for configuration files. Setting
`Sys.setenv(ODBCSYSINI = "some/folder")` means that your configuration
files should be located at `"/my/folder/odbc.ini"` and
`"/my/folder/odbcinst.ini"`. Be sure to set `ODBCSYSINI` *before*
loading the odbc package. That is:

- Restart R
- Run `Sys.setenv(ODBCSYSINI = "some/folder")`
- Load the odbc package with [`library(odbc)`](https://odbc.r-dbi.org)
- Test
  [`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
  and
  [`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
  again

If setting `ODBCSYSINI` resolves the issue you’ve noted, you may want to
set that environmental variable every time you start R. To do so, add an
entry like `ODBCSYSINI = some/folder` to your `~/.Renviron` file, which
contains environmental variables that are set every time an R session is
started. To open that file using R, run `usethis::edit_r_environ()`.

Once you’ve edited `~/.Renviron`, you’ll need to save the file and
restart R for changes to take effect.
