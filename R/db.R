# Oracle --------------------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Oracle", where = class_cache)

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

setMethod("sqlCreateTable", "Teradata",
  function(con, table, fields, field.types = NULL, row.names = NA, temporary = FALSE, ...) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
        "CREATE ", if (temporary) " MULTISET VOLATILE ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })

setMethod(
  "dbListTables", "Teradata",
  function(conn, ...) {
    c(dbGetQuery(conn, "HELP VOLATILE TABLE")[["Table SQL Name"]],
      connection_sql_tables(conn@ptr, ...)$table_name)
  })

# SAP HANA ----------------------------------------------------------------

setClass("HDB", where = class_cache)

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

setMethod(
  # only need to override dbQuteString when x is character.
  # DBI:::quote_string just returns x when it is of class SQL, so no need to override that.  
  "dbQuoteString", signature("Hive", "character"),
  function(conn, x, ...) {
    if (is(x, "SQL")) return(x)
    x <- gsub("'", "\\\\'", enc2utf8(x))
    if (length(x) == 0L) {
      DBI::SQL(character())
    } else {
      str <- paste0("'", x, "'")
      str[is.na(x)] <- "NULL"
      DBI::SQL(str)
    }
  })

# DB2 ----------------------------------------------------------------

setClass("DB2/AIX64", where = class_cache)

setMethod("sqlCreateTable", "DB2/AIX64",
  function(con, table, fields, field.types = NULL, row.names = NA, temporary = FALSE, ...) {
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
