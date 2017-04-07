library(DBI)

devtools::install()

pg <- dbConnect(odbc::odbc(), "PostgreSQL")
lapply(dbListTables(pg), dbRemoveTable, conn = pg)

msql <- dbConnect(odbc::odbc(), "MySQL")
lapply(dbListTables(msql), dbRemoveTable, conn = mysql)
