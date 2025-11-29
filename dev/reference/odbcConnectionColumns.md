# odbcConnectionColumns

**\[deprecated\]**

This function has been deprecated in favor of
[`DBI::dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html).

For a given table this function returns detailed information on all
fields / columns. The expectation is that this is a relatively thin
wrapper around the ODBC `SQLColumns` function call, with some of the
field names renamed / re-ordered according to the return specifications
below.

## Usage

``` r
odbcConnectionColumns(conn, name, ..., exact = FALSE)
```

## Arguments

- conn:

  OdbcConnection

- name:

  Table identifiers. By default, are interpreted as a ODBC search
  pattern where `_` and `%` are wild cards. Set `exact = TRUE` to match
  `_` exactly.

- ...:

  additional parameters to methods

- exact:

  Set to `TRUE` to escape `_` in identifier names so that it matches
  exactly, rather than matching any single character. `%` always matches
  any number of characters as this is unlikely to appear in a table
  name.

## Value

data.frame with columns

- name

- field.type - equivalent to type_name in SQLColumns output

- table_name

- schema_name

- catalog_name

- data_type

- column_size

- buffer_length

- decimal_digits

- numeric_precision_radix

- remarks

- column_default

- sql_data_type

- sql_datetime_subtype

- char_octet_length

- ordinal_position

- nullable

## Details

In
[`DBI::dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
we make a call to this method to get details on the fields of the table
we are writing to. In particular the columns `data_type`, `column_size`,
and `decimal_digits` are used. An implementation is not necessary for
[`DBI::dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
to work.

`odbcConnectionColumns` is routed through the `SQLColumns` ODBC method.
This function, together with remaining catalog functions (`SQLTables`,
etc), by default ( `SQL_ATTR_METADATA_ID == false` ) expect either
ordinary arguments (OA) in the case of the catalog, or pattern value
arguments (PV) in the case of schema/table name. For these, quoted
identifiers do not make sense, so we unquote identifiers prior to the
call.

## See also

The ODBC documentation on
[SQLColumns](https://learn.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
for further details.
