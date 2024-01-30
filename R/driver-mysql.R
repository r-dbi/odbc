#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("MySQL", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "MySQL",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "TEXT",
      datetime = "DATETIME",
      date = "DATE",
      time = "TIME",
      binary = "BLOB",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "DOUBLE",
      character = "TEXT",
      logical = "TINYINT",
      list = "TEXT",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
