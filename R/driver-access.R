#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("ACCESS", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "ACCESS",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = varchar(obj),
      datetime = "DATETIME",
      date = "DATE",
      time = "TIME",
      binary = "BINARY",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "DOUBLE",
      character = varchar(obj),
      logical = "BIT",
      list = varchar(obj),
      stop("Unsupported type", call. = FALSE)
    )
  }
)
