#' @export
#' @rdname DBI-classes
setClass("DB2/AIX64", contains = "OdbcConnection")

#' @rdname DBI-methods
# Don't generate a usage because there's some buglet in R CMD check
# (probably because of the `/` in the class name) which flags a usage
# without corresponding alias
#' @usage NULL
setMethod("sqlCreateTable", "DB2/AIX64",
  function(con,
           table,
           fields,
           row.names = NA,
           temporary = FALSE,
           ...,
           field.types = NULL) {
    check_bool(temporary)
    check_row.names(row.names)
    check_field.types(field.types)
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
      if (temporary) "DECLARE GLOBAL TEMPORARY" else "CREATE",
      " TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "),
      "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
    ))
  }
)

## Find temp tables in dbExistsTable and dbListTables on DB2

setMethod("dbExistsTable", c("DB2/AIX64", "Id"),
  function(conn, name, ...) {
    tryCatch(expr = {
      temptables = dbGetQuery(conn, "SELECT TABSCHEMA, TABNAME FROM SYSIBMADM.ADMINTEMPTABLES")
      # trim whitespace because sometimes schema are saved in the above table with extra whitespace
      return(any(trimws(temptables$TABNAME) == toupper(id_field(name, "table")) & 
                   trimws(temptables$TABSCHEMA == toupper(id_field(name, "schema")))) |
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
