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

# Query, rather than use SQLTables ODBC API for performance reasons on Oracle.
# Catalogs are not supported in ORACLE, so we only make use of schema and table name.
# If schema is provided we query `all_objects`.  Otherwise `user_objects`.
setMethod(
  "dbExistsTable", c("Oracle", "Id"),
  function(conn, name, ...) {
    schema_name <- id_field(name, "schema")
    table_name <- id_field(name, "table")

    if ( is.null(schema_name) )
    {
      return(dbExistsTable(conn, table_name))
    }
    query <- paste0(" SELECT object_name ",
                    " FROM all_objects ",
                    " WHERE owner='", schema_name ,"' AND object_name='", table_name, "'",
                    " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) ");
    df <- dbGetQuery(conn, query);
    NROW(df) > 0
  })

setMethod(
  "dbExistsTable", c("Oracle", "character"),
  function(conn, name, ...) {
    stopifnot(length(name) == 1)
    query <- paste0(" SELECT object_name ",
                    " FROM user_objects ",
                    " WHERE object_name='", name, "'",
                    " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) ");
    df <- dbGetQuery(conn, query);
    NROW(df) > 0
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

# Microsoft SQL Server ---------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Microsoft SQL Server", where = class_cache)

# For SQL Server, conn@quote will return the quotation mark, however
# both quotation marks as well as square bracket are used interchangeably for
# delimited identifiers.  See:
# https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers?view=sql-server-ver16
# Therefore strip the brackets first, and then call the DBI method that strips
# the quotation marks.
# TODO: the generic implementation in DBI should take a quote char as
# parameter.
setMethod("dbUnquoteIdentifier", c("Microsoft SQL Server", "SQL"),
  function(conn, x, ...) {
    x <- gsub("(\\[)([^\\.]+?)(\\])", "\\2", x)
    callNextMethod( conn, x, ... )
  })
