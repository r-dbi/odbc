suppressMessages(
# @rdname hidden_aliases
# @export
setMethod("sqlCreateTable", "Teradata",
  function(con, table, fields, row.names = NA, temporary = FALSE, ...) {
    table <- dbQuoteIdentifier(con, table)

    if (is.data.frame(fields)) {
      fields <- sqlRownamesToColumn(fields, row.names)
      fields <- vapply(fields, function(x) DBI::dbDataType(con, x), character(1))
    }

    field_names <- dbQuoteIdentifier(con, names(fields))
    field_types <- unname(fields)
    fields <- paste0(field_names, " ", field_types)

    SQL(paste0(
        "CREATE ", if (temporary) " MULTISET VOLATILE ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })
)

suppressMessages(
# @rdname hidden_aliases
# @export
setMethod(
  "dbListTables", "Teradata",
  function(conn, ...) {
    c(
      trimws(dbGetQuery(conn, "HELP VOLATILE TABLE")$`Table Name`),
      connection_sql_tables(conn@ptr, ...)$table_name
      )
  })
)
