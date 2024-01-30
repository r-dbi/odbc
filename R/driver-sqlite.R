#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("SQLite", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "SQLite",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "TEXT",
      datetime = "NUMERIC",
      date = "NUMERIC",
      binary = "BLOB",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "REAL",
      character = "TEXT",
      logical = "NUMERIC",
      list = "TEXT",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
