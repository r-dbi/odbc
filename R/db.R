# Oracle --------------------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Oracle")

#' @rdname hidden_aliases
#' @export
setMethod("sqlCreateTable", "Oracle",
  function(con, table, fields, field.types = NULL, row.names = NA, temporary = FALSE, ...) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
        "CREATE ", if (temporary) " GLOBAL TEMPORARY ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })

# Teradata --------------------------------------------------------------------

setClass("Teradata")

#' @rdname hidden_aliases
#' @export
setMethod("sqlCreateTable", "Teradata",
  function(con, table, fields, field.types = NULL, row.names = NA, temporary = FALSE, ...) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
        "CREATE ", if (temporary) " MULTISET VOLATILE ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })

#' @rdname hidden_aliases
#' @export
setMethod(
  "dbListTables", "Teradata",
  function(conn, ...) {
    c(dbGetQuery(conn, "HELP VOLATILE TABLE")[["Table SQL Name"]],
      connection_sql_tables(conn@ptr, ...)$table_name)
  })
