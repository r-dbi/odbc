### Issue Description and Expected Result
<!--Example: `dbGetQuery()` returns incorrect timestamps.-->

### Database
<!--Example: PostgreSQL 9.5, SQL Server 2012-->

### Reproducible Example
<!--
If possible include a _small_ dump of the table with the error and the R code
that generates the error. In your reprex please use `con` as the name of the
connection, this makes it easier to run locally.

The reprex package can be helpful in doing this.

    install.packages("reprex")
    reprex::reprex()

Example:
```r
library(odbc)
library(DBI)
con <- dbConnect(odbc::odbc(), dsn = "PostgreSQL")
dbWriteTable(con, "iris", iris)
dbReadTable(con, "iris")
```
-->

<details>
<summary>Session Info</summary>

```r
devtools::session_info()
#> output
```
</details>
