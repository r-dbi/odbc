library(DBI)

devtools::install()

pg <- dbConnect(odbc::odbc(), "PostgreSQL")
lapply(dbListTables(pg), dbRemoveTable, conn = pg)

mysql <- dbConnect(odbc::odbc(), "MySQL")
lapply(dbListTables(mysql), dbRemoveTable, conn = mysql)
