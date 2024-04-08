#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Teradata", contains = "OdbcConnection")

#' @rdname DBI-methods
setMethod("sqlCreateTable", "Teradata",
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
      "CREATE ", if (temporary) " MULTISET VOLATILE ", "TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
    ))
  }
)


setMethod("odbcConnectionTables", c("Teradata", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           table_type = NULL,
           exact = FALSE) {
    res <- callNextMethod()
    if (!is.null(schema_name)) {
      return(res)
    }

    # Also look through volatile tables if
    # not querying in a specific schema
    tempTableNames <- dbGetQuery(conn, "HELP VOLATILE TABLE")[["Table SQL Name"]]
    # If a name argument is supplied, subset the temp table names vector
    # to either an exact match, or if pattern value, to an approximate match
    if (!is.null(name)) {
      if (!exact && isPatternValue(name)) {
        name <- convertWildCards(name)
      } else {
        name <- escapePattern(name)
        name <- paste0("^", name, "$")
      }
      tempTableNames <- tempTableNames[grepl(name, tempTableNames)]
    }

    navec <- rep(NA_character_, length(tempTableNames))
    rbind(
      res,
      data.frame(
        table_catalog = navec,
        table_schema = navec,
        table_name = tempTableNames,
        table_remarks = navec,
        stringsAsFactors = FALSE
      )
    )
  }
)


#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Teradata",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "VARCHAR(255)",
      datetime = "TIMESTAMP",
      date = "DATE",
      time = "TIME",
      binary = "BLOB",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "FLOAT",
      character = "VARCHAR(255)",
      logical = "BYTEINT",
      list = "VARCHAR(255)",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
