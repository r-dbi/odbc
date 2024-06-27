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

## Find temp tables in dbExistsTable and dbListTables on DB2

setMethod("dbExistsTable", c("DB2/AIX64", "Id"),
  function(conn, name, ...) {
    tryCatch(expr = {
      temptables = dbGetQuery(conn, "SELECT TABSCHEMA, TABNAME, INSTANTIATOR FROM SYSIBMADM.ADMINTEMPTABLES")
      # trim whitespace because sometimes schema are saved in the above table with extra whitespace
      return(any(trimws(temptables$TABNAME) == toupper(id_field(name, "table")) & 
                   trimws(temptables$TABSCHEMA == toupper(id_field(name, "schema"))) &
                   tolower(trimws(temptables$INSTANTIATOR)) == tolower(conn@info$username)
                   ) |
               name@name[["table"]] %in%
               connection_sql_tables(conn@ptr,
                                     catalog_name = id_field(name, "catalog"),
                                     schema_name = id_field(name, "schema"),
                                     table_name = id_field(name, "table"))
             )
      },
      error = function(cond) {
        return(name@name[["table"]] %in%
                 connection_sql_tables(conn@ptr,
                                       catalog_name = id_field(name, "catalog"),
                                       schema_name = id_field(name, "schema"),
                                       table_name = id_field(name, "table"))
               )
      }
    )
  }
)

setMethod("dbListTables", "DB2/AIX64",
  function(conn, ...) {
    tryCatch(return(c(dbGetQuery("SELECT TABNAME FROM SYSIBMADM.ADMINTEMPTABLES")[["TABNAME"]],
                      connection_sql_tables(conn@ptr)$table_name)
                    ),
             error = function(cond) {
               return(connection_sql_tables(conn@ptr)$table_name)
              }
             )
  }
)
