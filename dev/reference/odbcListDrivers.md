# List Configured ODBC Drivers

Collect information about the configured driver names. A driver must be
both installed and configured with the driver manager to be included in
this list. Configuring a driver name just sets up a lookup table (e.g.
in `odbcinst.ini`) to allow users to pass only the driver name to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

Driver names that are not configured with the driver manager (and thus
do not appear in this function's output) can still be used in
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
by providing a path to a driver directly.

## Usage

``` r
odbcListDrivers(
  keep = getOption("odbc.drivers_keep"),
  filter = getOption("odbc.drivers_filter")
)
```

## Arguments

- keep, filter:

  A character vector of driver names to keep in or remove from the
  results, respectively. If `NULL`, all driver names will be kept, or
  none will be removed, respectively. The `odbc.drivers_keep` and
  `odbc.drivers_filter` options control the argument defaults.

  Driver names are first processed with `keep`, then `filter`. Thus, if
  a driver name is in both `keep` and `filter`, it won't appear in
  output.

## Value

A data frame with three columns.

- name:

  Name of the driver. The entries in this column can be passed to the
  `driver` argument of
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  (as long as the driver accepts the argument).

- attribute:

  Driver attribute name.

- value:

  Driver attribute value.

If a driver has multiple attributes, there will be one row per
attribute, each with the same driver `name`. If a given driver name does
not have any attributes, the function will return one row with the
driver `name`, but the last two columns will be `NA`.

## Configuration

This function interfaces with the driver manager to collect information
about the available driver names.

For **MacOS and Linux**, the odbc package supports the unixODBC driver
manager. unixODBC looks to the `odbcinst.ini` *configuration file* for
information on driver names. Find the location(s) of your `odbcinst.ini`
file(s) with `odbcinst -j`.

In this example `odbcinst.ini` file:

    [MySQL Driver]
    Driver=/opt/homebrew/Cellar/mysql/8.2.0_1/lib/libmysqlclient.dylib

Then the driver name is `MySQL Driver`, which will appear in the `name`
column of this function's output. To pass the driver name as the
`driver` argument to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md),
pass it as a string, like `"MySQL Driver"`.

**Windows** is
[bundled](https://learn.microsoft.com/en-us/sql/odbc/admin/odbc-data-source-administrator)
with an ODBC driver manager.

In this example, function output would include 1 row: the `name` column
would read `"MySQL Driver"`, `attribute` would be `"Driver"`, and
`value` would give the file path to the driver. Additional key-value
pairs under the driver name would add additional rows with the same
`name` entry.

When a driver is configured with a driver manager, information on the
driver will be automatically passed on to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
when its `driver` argument is set. For an example, see the same section
in the
[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
help-file. Instead of configuring driver information with a driver
manager, it is also possible to provide a path to a driver directly to
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## See also

[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)

## Examples

``` r
if (FALSE) {
odbcListDrivers()
}
```
