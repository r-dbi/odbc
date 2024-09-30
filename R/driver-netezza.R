#' @export
#' @rdname DBI-classes
setClass("NetezzaSQL", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "NetezzaSQL",
  function(con, obj, ...) {
    switch_type(
      obj,
      character = varchar(obj),
      logical = "BOOL",
      callNextMethod(con, obj, ...)
    )
  }
)
