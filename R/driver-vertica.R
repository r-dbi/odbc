#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Vertica Database", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Vertica Database",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "VARCHAR",
      datetime = "TIMESTAMP",
      date = "DATE",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "DOUBLE PRECISION",
      character = "VARCHAR",
      logical = "BOOLEAN",
      list = "VARCHAR",
      time = "TIME",
      binary = "VARBINARY",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
