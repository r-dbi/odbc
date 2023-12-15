#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("HDB", contains = "OdbcConnection")

#' @rdname DBI-methods
setMethod("sqlCreateTable", "HDB",
  function(con,
           table,
           fields,
           row.names = NA,
           temporary = FALSE,
           ...,
           field.types = NULL) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
      "CREATE ", if (temporary) "LOCAL TEMPORARY COLUMN ",
      "TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "),
      "\n)\n"
    ))
  }
)
