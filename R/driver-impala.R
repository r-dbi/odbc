#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Impala", contains = "OdbcConnection")

# TODO: Revisit binary type (Impala)
#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Impala",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "STRING",
      datetime = "STRING",
      date = "VARCHAR(10)",
      integer = "INT",
      int64 = "INT",
      double = "DOUBLE",
      character = "STRING",
      logical = "BOOLEAN",
      list = "STRING",
      time = ,
      stop("Unsupported type", call. = FALSE)
    )
  }
)
