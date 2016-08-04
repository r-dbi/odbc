#' ODBC connection class.
#' 
#' @export
#' @keywords internal
setClass("ODBCConnection",
  contains = "DBIConnection",
  slots = list(
    host = "character",
    username = "character",
    # and so on
    ptr = "externalptr"
  )
)

#' @param drv An object created by \code{ODBC()}
#' @rdname ODBC
#' @export
#' @examples
#' \dontrun{
#' db <- dbConnect(RODBC::ODBC())
#' dbWriteTable(db, "mtcars", mtcars)
#' dbGetQuery(db, "SELECT * FROM mtcars WHERE cyl == 4")
#' }
setMethod("dbConnect", "ODBCDriver", function(drv, ...) {

  new("ODBCConnection", host = host, ...)
})
