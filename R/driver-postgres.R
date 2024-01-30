#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("PostgreSQL", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "PostgreSQL",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "TEXT",
      datetime = "TIMESTAMP",
      date = "DATE",
      time = "TIME",
      binary = "bytea",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "DOUBLE PRECISION",
      character = "TEXT",
      logical = "BOOLEAN",
      list = "TEXT",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
