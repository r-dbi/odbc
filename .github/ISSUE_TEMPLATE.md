### Issue Description and Expected Result
<!--Example: `dbGetQuery()` returns incorrect timestamps.-->

### Database
<!--Example: PostgreSQL 9.5, SQL Server 2012-->

### Reproducible Example
<!--
If possible include a _small_ dump of the table with the error and the R code
that generates the error.

Example:
```r
library(odbconnect)
library(DBI)
con <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
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
