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
