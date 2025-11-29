# Quote special character when connecting

When connecting to a database using odbc, all the arguments are
concatenated into a single connection string that looks like
`name1=value1;name2=value2`. That means if your value contains `=` or
`;` then it needs to be quoted. Other rules mean that you need to quote
any values that starts or ends with white space, or contains `{` or `}`.

This function quotes a string in a way that should work for most
drivers, but unfortunately there doesn't seem to be an approach that
works everywhere. If this function doesn't work for you, you'll need to
carefully read the docs for your driver.

## Usage

``` r
quote_value(x)
```

## Arguments

- x:

  A string to quote.

## Value

A quoted string, wrapped in [`I()`](https://rdrr.io/r/base/AsIs.html).

## Examples
