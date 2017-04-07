library(DBI)

devtools::load_all()

pg <- dbConnect(odbc::odbc(), "PostgreSQL")
lapply(dbListTables(pg), dbRemoveTable)

msql <- dbConnect(odbc::odbc(), "MySQL")
lapply(dbListTables(msql), dbRemoveTable)
