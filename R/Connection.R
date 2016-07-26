#' ODBC connection class.
#' 
#' @export
#' @keywords internal
setClass("ODBCConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr"
  )
)
