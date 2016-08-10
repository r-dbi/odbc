#' ODBConnect results class.
#'
#' @keywords internal
#' @export
setClass("ODBConnectResult",
  contains = "DBIResult",
  slots = list(ptr = "externalptr")
)

#' Send a query to ODBConnect.
#'
#' @export
#' @examples
#' # This is another good place to put examples
setMethod("dbSendQuery", "ODBConnectConnection", function(conn, statement, buffer_size = 4096, ...) {
  ptr <- query(conn@ptr, statement, buffer_size)
  new("ODBConnectResult", ptr = ptr)
})


#' Retrieve records from ODBConnect query
#' @export
setMethod("dbFetch", "ODBConnectResult", function(res, ...) {
  fetch(res@ptr)
})

#' @export
setMethod("dbHasCompleted", "ODBConnectResult", function(res, ...) {
  has_completed(res@ptr)
})
