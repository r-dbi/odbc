# List the actions supported for the connection

**\[deprecated\]**

Return a list of actions that can be performed on the connection.

## Usage

``` r
odbcConnectionActions(connection)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## Value

A named list of actions that can be performed on the connection.

## Details

The list returned is a named list of actions, where each action has the
following properties:

- callback:

  A function to be invoked to perform the action

- icon:

  An optional path to an icon representing the action
