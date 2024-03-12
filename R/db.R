#' @include odbc-connection.R
NULL

#' Helper method used to determine if a table identifier is that
#' of a temporary table.
#'
#' Currently implemented only for select back-ends where
#' we have a use for it (SQL Server, for example).  Generic, in case
#' we develop a broader use case.
#' @param conn OdbcConnection
#' @param name Table name
#' @param ... additional parameters to methods
#' @rdname isTempTable
#' @export
setGeneric(
  "isTempTable",
  valueClass = "logical",
  function(conn, name, ...) {
    standardGeneric("isTempTable")
  }
)

#' @rdname isTempTable
setMethod("isTempTable", c("OdbcConnection", "Id"),
  function(conn, name, ...) {
    isTempTable(conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      ...
    )
  }
)

#' @rdname isTempTable
setMethod("isTempTable", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    isTempTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)
