#' Return the corresponding ODBC data type for an R object
#'
#' This is used when creating a new table with `dbWriteTable()`.
#' Databases with default methods defined are
#' - MySQL
#' - PostgreSQL
#' - SQL Server
#' - SQLite
#' - Spark
#' - Hive
#'
#' If you are using a different database and `dbWriteTable()` fails with a SQL
#' parsing error the default method is not appropriate, you will need to write
#' a new method.
#'
#' @section Defining a new dbDataType method:
#'
#' The object type for your connection will be the database name retrieved by
#' `dbGetInfo(con)$dbms.name`. Use the documentation provided with your
#' database to determine appropriate values for each R data type. An example
#' method definition of a fictional `foo` database follows.
#' ```
#' con <- dbConnect(odbc::odbc(), "FooConnection")
#' dbGetInfo(con)$dbms.name
#' #> [1] "foo"
#'
#' `odbcDataType.foo <- function(info, obj, ...) {
#'   switch_type(obj,
#'     factor = "VARCHAR(255)",
#'     datetime = "TIMESTAMP",
#'     date = "DATE",
#'     binary = "BINARY",
#'     integer = "INTEGER",
#'     double = "DOUBLE",
#'     character = "VARCHAR(255)",
#'     logical = "BIT",
#'     list = "VARCHAR(255)",
#'     stop("Unsupported type", call. = FALSE)
#'   )
#' }
#' ```
#' @param info A driver information object, as returned by `dbGetInfo()`.
#' @param obj An R object.
#' @return Corresponding SQL type for the `obj`.
#' @export
odbcDataType <- function(info, obj, ...) UseMethod("odbcDataType")

#' @export
odbcDataType.default <- function(info, obj, ...) {
  switch_type(obj,
    factor = "VARCHAR(255)",
    datetime = "TIMESTAMP",
    date = "DATE",
    binary = "BINARY",
    integer = "INTEGER",
    double = "DOUBLE",
    character = "VARCHAR(255)",
    logical = "VARCHAR(5)", # Needs to be able to handle NA as well as TRUE, FALSE
    list = "VARCHAR(255)",
    stop("Unsupported type", call. = FALSE)
  )
}

#' @export
`odbcDataType.Spark SQL` <- function(info, obj, ...) {
  switch_type(obj,
    factor = "VARCHAR(255)",
    datetime = "DATE",
    date = "DATE",
    binary = "BINARY",
    integer = "INT",
    double = "DOUBLE",
    character = "VARCHAR(255)",
    logical = "BOOLEAN",
    list = "VARCHAR(255)",
    stop("Unsupported type", call. = FALSE)
  )
}

#' @export
`odbcDataType.Hive` <- function(info, obj, ...) {
  switch_type(obj,
    factor = "STRING",
    datetime = "TIMESTAMP",
    date = "DATE",
    binary = "BINARY",
    integer = "INT",
    double = "DOUBLE",
    character = "STRING",
    logical = "BOOLEAN",
    list = "STRING",
    stop("Unsupported type", call. = FALSE)
  )
}
  
#' @export
`odbcDataType.MySQL` <- function(info, obj, ...) {
  switch_type(obj,
    factor = "TEXT",
    datetime = "DATETIME",
    date = "DATE",
    binary = "BLOB",
    integer = "INTEGER",
    double = "DOUBLE",
    character = "TEXT",
    logical = "TINYINT",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

#' @export
`odbcDataType.PostgreSQL` <- function(info, obj, ...) {
  switch_type(obj,
    factor = "TEXT",
    datetime = "TIMESTAMP",
    date = "DATE",
    binary = "bytea",
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

#' @export
`odbcDataType.Microsoft SQL Server` <- function(info, obj, ...) {
  switch_type(obj,
    factor = varchar(obj),
    datetime = "DATETIME",
    date = "DATE",
    binary = varbinary(obj),
    integer = "INT",
    double = "FLOAT",
    character = varchar(obj),
    logical = "BIT",
    list = varchar(obj),
    stop("Unsupported type", call. = FALSE)
  )
}

#' @export
`odbcDataType.SQLite` <- function(info, obj, ...) {
  switch_type(obj,
    factor = "TEXT",
    datetime = "NUMERIC",
    date = "NUMERIC",
    binary = "BLOB",
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "NUMERIC",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

switch_type <- function(obj, ...) {
  switch(object_type(obj), ...)
}

object_type <- function(obj) {
  if (is.factor(obj)) return("factor")
  if (is(obj, "POSIXct")) return("datetime")
  if (is(obj, "Date")) return("date")
  if (is(obj, "blob")) return("binary")

  return(typeof(obj))
}

varchar <- function(x, type = "varchar") {
  max_length <- max(nchar(as.character(x)), na.rm = TRUE)
  paste0(type, "(", max(255, max_length), ")")
}

varbinary <- function(x, type = "varbinary") {
  max_length <- max(lengths(x), na.rm = TRUE)
  paste0(type, "(", max(255, max_length), ")")
}
