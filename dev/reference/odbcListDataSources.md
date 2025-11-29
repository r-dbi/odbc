# List Configured Data Source Names

Collect information about the available data source names (DSNs). A DSN
must be both installed and configured with the driver manager to be
included in this list. Configuring a DSN just sets up a lookup table
(e.g. in `odbc.ini`) to allow users to pass only the DSN to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

DSNs that are not configured with the driver manager can still be
connected to with
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
by providing DSN metadata directly.

## Usage

``` r
odbcListDataSources()
```

## Value

A data frame with two columns:

- name:

  Name of the data source. The entries in this column can be passed to
  the `dsn` argument of
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- description:

  Data source description.

## Configuration

This function interfaces with the driver manager to collect information
about the available data source names.

For **MacOS and Linux**, the odbc package supports the unixODBC driver
manager. unixODBC looks to the `odbc.ini` *configuration file* for
information on DSNs. Find the location(s) of your `odbc.ini` file(s)
with `odbcinst -j`.

In this example `odbc.ini` file:

    [MySQL]
    Driver = MySQL Driver
    Database = test
    Server = 127.0.0.1
    User = root
    password = root
    Port = 3306

...the data source name is `MySQL`, which will appear in the `name`
column of this function's output. To pass the DSN as the `dsn` argument
to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md),
pass it as a string, like `"MySQL"`. `Driver = MySQL Driver` references
the driver `name` in
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
output.

**Windows** is
[bundled](https://learn.microsoft.com/en-us/sql/odbc/admin/odbc-data-source-administrator)
with an ODBC driver manager.

When a DSN is configured with a driver manager, information on the DSN
will be automatically passed on to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
when its `dsn` argument is set.

For example, with the `MySQL` data source name configured, and the
driver name `MySQL Driver` appearing in
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
output, the code:

    con <-
      dbConnect(
        odbc::odbc(),
        Driver = "MySQL Driver",
        Database = "test",
        Server = "127.0.0.1",
        User = "root",
        password = "root",
        Port = 3306
      )

...can be written:

    con <- dbConnect(odbc::odbc(), dsn = "MySQL")

In this case,
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
will look up the information defined for `MySQL` in the driver manager
(in our example, `odbc.ini`) and automatically pass the needed
arguments.

## See also

[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
