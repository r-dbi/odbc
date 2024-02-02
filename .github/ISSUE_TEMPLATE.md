
<!--First, describe the problem, e.g. `dbGetQuery()` returns incorrect timestamps.-->

<!--
If possible include a _small_ dump of the table with the error and the R code
that generates the error. In your reprex please use `con` as the name of the
connection, and don't forget to delete any secrets like your password.

The reprex package can be helpful in doing this.

    install.packages("reprex")
    reprex::reprex()

Example:

```r
library(DBI)
con <- dbConnect(odbc::odbc(), dsn = "PostgreSQL")
dbWriteTable(con, "iris", iris)
dbReadTable(con, "iris")
```
-->


<details>
<summary>Database</summary>

```r
DBI::dbGetInfo(con)
#> output
```
</details>


<details>
<summary>Session Info</summary>

```r
devtools::session_info()
#> output
```
</details>


