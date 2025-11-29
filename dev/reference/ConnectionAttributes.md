# Supported Connection Attributes

These (pre) connection attributes are supported and can be passed as
part of the `dbConnect` call in the named list `attributes` parameter:

## Details

- `azure_token`: This should be a string scalar; in particular Azure
  Active Directory authentication token. Only for use with Microsoft SQL
  Server and with limited support away from the OEM Microsoft driver.

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- dbConnect(
  odbc::odbc(),
  dsn = "my_azure_mssql_db",
  Encrypt = "yes",
  attributes = list("azure_token" = .token)
)
} # }
```
