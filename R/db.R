# Oracle --------------------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Oracle", where = class_cache)

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

setClass("Teradata", where = class_cache)

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

# SAP HANA ----------------------------------------------------------------

setClass("HDB", where = class_cache)

#' @rdname hidden_aliases
#' @export
setMethod("sqlCreateTable", "HDB",
  function(con, table, fields, field.types = NULL, row.names = NA, temporary = FALSE, ...) {
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

# Hive --------------------------------------------------------------------

setClass("Hive", where = class_cache)

#' @rdname hidden_aliases
#' @export
setMethod(
  # only need to override dbQuteString when x is character.
  # DBI:::quote_string just returns x when it is of class SQL, so no need to override that.  
  "dbQuoteString", signature("Hive", "character"),
  function(conn, x, ...) {
    if (is(x, "SQL")) return(x)
    if (!is.character(x)) stop("x must be character or SQL", call. = FALSE)
    x <- gsub("'", "\\'", enc2utf8(x))
    if (length(x) == 0L) {
      DBI::SQL(character())
    } else {
      str <- paste("'", x, "'", sep = "")
      str[is.na(x)] <- "NULL"
      DBI::SQL(str)
    }
  })
