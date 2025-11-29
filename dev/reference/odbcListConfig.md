# List locations of ODBC configuration files

On MacOS and Linux, odbc uses the unixODBC driver manager to manage
information about driver and data sources. This helper returns the
filepaths where the driver manager will look for that information.

`odbcListConfig()` is a wrapper around the command line call
`odbcinst -j`. The `odbcEditDrivers()`, `odbcEditSystemDSN()`, and
`odbcEditUserDSN()` helpers provide a shorthand for
`file.edit(odbcListConfig()[[i]])`.

Windows does not use `.ini` configuration files; on Windows,
`odbcListConfig()` will return a 0-length vector and `odbcEdit*()` will
raise an error.

## Usage

``` r
odbcListConfig()

odbcEditDrivers()

odbcEditSystemDSN()

odbcEditUserDSN()
```

## See also

The
[`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
and
[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
helpers return information on the contents of `odbcinst.ini` and
`odbc.ini` files, respectively.
[`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
collates entries from both the System and User `odbc.ini` files.

Learn more about unixODBC and the `odbcinst` utility
[here](https://www.unixodbc.org/odbcinst.html).

## Examples

``` r
if (FALSE) {
configs <- odbcListConfig()

configs

# shorthand for file.edit(configs[[1]])
odbcEditDrivers()
}
```
