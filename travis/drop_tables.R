library(DBI)

devtools::install()

pg <- dbConnect(odbc::odbc(), "PostgreSQL")
lapply(dbListTables(pg), dbRemoveTable)

msql <- dbConnect(odbc::odbc(), "MySQL")
lapply(dbListTables(msql), dbRemoveTable)
