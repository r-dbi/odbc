#' ODBC connection class.
#' 
#' @export
#' @include Connection.R
#' @keywords internal
setClass("ODBConnectConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr"
  )
)

#' @param drv An object created by \code{ODBC()}
#' @rdname ODBC
#' @export
#' @include driver.R
#' @examples
#' \dontrun{
#' db <- dbConnect(odbconnect::odbconnect(), "DSN=database1")
#' dbWriteTable(db, "mtcars", mtcars)
#' dbGetQuery(db, "SELECT * FROM mtcars WHERE cyl == 4")
#' }
setMethod("dbConnect", "ODBConnectDriver", function(drv, connection_string, ...) {

  ptr <- connect(connection_string)
  new("ODBConnectConnection", ptr = ptr)
})
