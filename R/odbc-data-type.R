#' Return the corresponding ODBC data type for an R object
#'
#' This is used when creating a new table with `dbWriteTable()`.
#' Databases with default methods defined are
#' - MySQL
#' - PostgreSQL
#' - SQL Server
#' - Oracle
#' - SQLite
#' - Spark
#' - Hive
#' - Impala
#' - Redshift
#' - Vertica
#' - BigQuery
#' - Teradata
#' - Access
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
#' `odbcDataType.foo <- function(con, obj, ...) {
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
#' @param con A driver connection object, as returned by `dbConnect()`.
#' @param obj An R object.
#' @param ... Additional arguments passed to methods.
#' @return Corresponding SQL type for the `obj`.
#' @export
odbcDataType <- function(con, obj, ...) UseMethod("odbcDataType")

#' @export
odbcDataType.default <- function(con, obj, ...) {
  switch_type(obj,
    factor = "VARCHAR(255)",
    datetime = "TIMESTAMP",
    date = "DATE",
    time = "TIME",
    binary = "VARBINARY(255)",
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "VARCHAR(255)",
    logical = "BIT", # only valid if DB supports Null fields
    list = "VARCHAR(255)",
    stop("Unsupported type", call. = FALSE)
  )
}

switch_type <- function(obj, ...) {
  switch(object_type(obj),
    ...
  )
}

object_type <- function(obj) {
  if (is.factor(obj)) {
    return("factor")
  }
  if (is(obj, "POSIXct")) {
    return("datetime")
  }
  if (is(obj, "Date")) {
    return("date")
  }
  if (is_blob(obj)) {
    return("binary")
  }
  if (is(obj, "difftime")) {
    return("time")
  }
  if (is(obj, "integer64")) {
    return("int64")
  }

  return(typeof(obj))
}

is_blob <- function(obj) {
  if (is(obj, "blob")) {
    return(TRUE)
  }
  if (is.object(obj) && any(class(obj) != "AsIs")) {
    return(FALSE)
  }
  if (!is.list(obj)) {
    return(FALSE)
  }

  # Assuming raw inside naked lists if the first non-NULL element is raw,
  # not checking the other elements
  for (i in seq_along(obj)) {
    x <- obj[[i]]
    if (!is.null(x)) {
      return(is.raw(x))
    }
  }

  TRUE
}

varchar <- function(x, type = "varchar") {
  # at least 255 characters, use max if more than 8000:
  max_length <- max(c(255, nchar(as.character(x))), na.rm = TRUE)

  if (max_length > 8000) {
    max_length <- "max"
  }

  paste0(type, "(", max_length, ")")
}

varbinary <- function(x, type = "varbinary") {
  # at least 255 bytes, use max if more than 8000:
  max_length <- max(c(255, lengths(x)), na.rm = TRUE)

  if (max_length > 8000) {
    max_length <- "max"
  }

  paste0(type, "(", max_length, ")")
}
