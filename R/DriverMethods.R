
connection_icon.SQLite <- function(connection, ...) {
  system.file(file.path("icons", "SQLite.png"), package = "odbc")
}

connection_icon.PostgreSQL <- function(connection, ...) {
  system.file(file.path("icons", "PostgreSQL.png"), package = "odbc")
}
