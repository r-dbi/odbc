#' @export
#' @rdname DBI-classes
setClass("DB2/AIX64", contains = "OdbcConnection")
setClass("DB2/LINUXX8664", contains = "DB2/AIX64")

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


#' @rdname DBI-methods
# In addition to the `ODBC` API call to `SQLTables`, also
# attempt to query SYSIBMADM.ADMINTEMPTABLES for any tables
# that match the arguments.
#' @usage NULL
setMethod("odbcConnectionTables", c("DB2/AIX64", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           table_type = NULL,
           exact = FALSE) {

    res <- callNextMethod()
    dfTempTables <- NULL
    if ( (is.null(schema_name) || schema_name == "SESSION") &&
         (is.null(catalog_name) || tolower(catalog_name) == conn@info$username) ) {
      # Also look for temp tables in this case
      # Notes on DB2 temp tables:
      # https://www.ibm.com/docs/en/db2-for-zos/12?topic=statements-declare-global-temporary-table
      # Notes on DB2 ADMINTEMPTABLES admin view:
      # https://www.ibm.com/docs/en/db2woc?topic=aracp-admin-get-temp-tables-retrieve-information-temporary-tables
      qTable <- getSelector("TABNAME", name, exact)
      qSchema <- getSelector("TABSCHEMA", schema_name, exact)
      query <- paste0(
        "SELECT
            INSTANTIATOR AS \"table_catalog\",
            TABSCHEMA AS \"table_schema\",
            TABNAME AS \"table_name\",
            'TABLE' AS \"table_type\",
            NULL AS \"table_remarks\"
         FROM SYSIBMADM.ADMINTEMPTABLES ",
        "WHERE 1 = 1 ", qTable, qSchema)
      tryCatch({
        dfTempTables <- dbGetQuery(conn, query)
        # NULL as colname is not well liked by DB2 it seems. Hack here.
        dfTempTables$table_remarks <- NA_character_
      }, odbc_database_error = function(e) {
        cli::cli_warn("Unable to query for temporary tables in SYSIBMADM.ADMINTEMPTABLES")
      })
    }
    rbind(res, dfTempTables)
  }
)
