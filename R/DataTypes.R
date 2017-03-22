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

#' Test round tripping a simple table
#'
#' This tests all the supported data types, including missing values. It first
#' writes them to the database, then reads them back and verifies the data is
#' identical to the original.
#'
#' This function is not exported and should only be used during tests and as a
#' sanity check when writing new `odbcDataType()` methods.
#'
#' @param con An established DBI connection.
#' @param columns Table columns to exclude (default) or include, dependent on
#' the value of `invert`. One of `datetime`, `date`, `binary`,
#' `integer`, `double`, `character`, `logical`.
#' @param invert If `TRUE`, change the definition of columns to be inclusive,
#' rather than exclusive.
#' \dontrun{
#' test_roundtrip(con)
#'
#' # exclude a few columns
#' test_roundtrip(con, c("integer", "double"))
#'
#' # Only test a specific column
#' test_roundtrip(con, "integer", invert = FALSE)
#' }
test_roundtrip <- function(con = DBItest:::connect(DBItest:::get_default_context()), columns = "", invert = TRUE) {
  dbms <- dbGetInfo(con)$dbms.name
  testthat::context(paste0("roundtrip[", dbms, "]"))
  testthat::test_that(paste0("[", dbms, "] round tripping data.frames works"), {
    on.exit(try(DBI::dbRemoveTable(con, "it"), silent = TRUE))
    set.seed(42)

    # We can't use the data.frame constructor directly as list columns don't work there.
    it <- list(

      # We always return strings as factors
      #factor = iris$Species,

      datetime = as.POSIXct(as.numeric(iris$Petal.Length * 10), origin = "2016-01-01", tz = "UTC"),
      date = as.Date(iris$Sepal.Width * 100, origin = Sys.time()),
      binary = blob::as.blob(lapply(seq_len(NROW(iris)), function(x) as.raw(sample(0:100, size = sample(0:25, 1))))),
      integer = as.integer(iris$Petal.Width * 100),
      double = iris$Sepal.Length,
      character = as.character(iris$Species),
      logical = sample(c(TRUE, FALSE), size = nrow(iris), replace = T)
    )
    attributes(it) <- list(names = names(it), row.names = c(NA_integer_, -length(it[[1]])), class = "data.frame")

    # Add a proportion of NA values to a data frame
    add_na <- function(x, p = .1) { is.na(x) <- runif(length(x)) < p; x}
    it[] <- lapply(it, add_na, p = .1)
    if (isTRUE(invert)) {
      it <- it[, !names(it) %in% columns]
    } else {
      it <- it[, names(it) %in% columns]
    }

    DBI::dbWriteTable(con, "it", it, overwrite = TRUE)
    res <- DBI::dbReadTable(con, "it")
    testthat::expect_equal(it, res)
  })
}
