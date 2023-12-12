
#' Helper method used to determine if a table identifier is that
#' of a temporary table.
#'
#' Currently implemented only for select back-ends where
#' we have a use for it (SQL Server, for example).  Generic, in case
#' we develop a broader use case.
#' @param conn OdbcConnection
#' @param name Table name
#' @param ... additional parameters to methods
#' @rdname isTempTable
#' @export
setGeneric(
  "isTempTable",
  valueClass = "logical",
  function(conn, name, ...) {
    standardGeneric("isTempTable")
  }
)

#' @rdname isTempTable
setMethod(
  "isTempTable",
  c("OdbcConnection", "Id"),
  function(conn, name, ...) {
    isTempTable(conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      ...)
  }
)

#' @rdname isTempTable
setMethod(
  "isTempTable",
  c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    isTempTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

# Oracle --------------------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Oracle", where = class_cache)

#' @rdname DBI-methods
setMethod("sqlCreateTable", "Oracle",
  function(con, table, fields, row.names = NA, temporary = FALSE, ..., field.types = NULL) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
        "CREATE ", if (temporary) " GLOBAL TEMPORARY ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })

#' @rdname odbcConnectionTables
#' @details Query, rather than use SQLTables ODBC API for performance reasons on Oracle.
#' Main functional difference between the implementation of SQLTables ( OEM driver )
#' and the query below is that the OEM implementation also looks through the synonyms.
#' Given the performance reports, we sacrifice the synonym look-through for
#' better execution time.
setMethod(
  "odbcConnectionTables",
  c("Oracle", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, table_type = NULL, exact = FALSE) {

    qTable <- getSelector("object_name", name, exact)
    if (is.null(schema_name)) {
      query <- paste0(
        " SELECT null AS \"table_catalog\", '", conn@info$username ,"' AS \"table_schema\", object_name AS \"table_name\", object_type AS \"table_type\", null AS \"table_remarks\"",
        " FROM user_objects ",
        " WHERE 1 = 1 ", qTable,
        " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) ")
    } else {
      qSchema <- getSelector("owner", schema_name, exact)
      query <- paste0(
        " SELECT null AS \"table_catalog\", owner AS \"table_schema\", object_name AS \"table_name\", object_type AS \"table_type\", null AS \"table_remarks\"",
        " FROM all_objects ",
        " WHERE 1 = 1 ", qSchema, qTable,
        " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) ")
    }

    dbGetQuery(conn, query)
  })

#' @rdname odbcConnectionColumns
#' @details Query, rather than use SQLColumns ODBC API for ORACLE since when using the API
#' we bind a BIGINT to one of the column results.  Oracle's OEM driver is unable to handle.
setMethod(
  "odbcConnectionColumns",
  c("Oracle", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, column_name = NULL, exact = FALSE) {

    query <- ""
    baseSelect <- paste0(
      "SELECT
      column_name AS \"name\",
      data_type AS \"field.type\",
      table_name AS \"table_name\",
      owner AS \"schema_name\",
      null AS \"catalog_name\",
      null AS \"data_type\",
      decode(data_type,'CHAR',char_length,'NCHAR',char_length, 'VARCHAR2',char_length,'NVARCHAR2',char_length, 'RAW',data_length, 'ROWID', data_length, 'UNDEFINED', 0, data_precision) AS \"column_size\",
      decode(data_type, 'DATE',16,'FLOAT',8,'BINARY_FLOAT',4,'BINARY_DOUBLE',8,'LONG RAW',2147483647,'LONG',2147483647,'CLOB',2147483647,'NCLOB',2147483647,'BLOB',2147483647,'BFILE',2147483647,'CHAR',data_length,'NCHAR',data_length,'VARCHAR2',data_length,'NVARCHAR2',data_length,'NUMBER',NVL(data_precision+2,40),data_length) AS \"buffer_length\",
      data_scale AS \"decimal_digits\",
      null AS \"numeric_precision_radix\",
      null AS \"remarks\",
      null AS \"column_default\",
      null AS \"sql_data_type\",
      null AS \"sql_datetime_subtype\",
      decode(data_type,'CHAR',data_length,'VARCHAR2',data_length,'NVARCHAR2',data_length,'NCHAR',data_length, 0) AS \"char_octet_length\",
      column_id AS \"ordinal_position\",
      decode(nullable, 'Y', 1, 'N', 0) AS \"nullable\"")
    qTable <- getSelector("table_name", name, exact)
    if (is.null(schema_name)) {
      baseSelect <- gsub("owner AS \"schema_name\"", paste0("'", conn@info$username, "' AS \"schema_name\""), baseSelect);
      query <- paste0(
         baseSelect,
         " FROM user_tab_columns ",
         " WHERE 1 = 1 ", qTable );
    } else {
      qSchema <- getSelector("owner", schema_name, exact)
      query <- paste0(
        baseSelect,
        " FROM all_tab_columns ",
        " WHERE 1 = 1 ", qSchema, qTable )
    }

    dbGetQuery(conn, query);
  })

# Teradata --------------------------------------------------------------------

setClass("Teradata", where = class_cache)

#' @rdname DBI-methods
setMethod("sqlCreateTable", "Teradata",
  function(con, table, fields, row.names = NA, temporary = FALSE, ..., field.types = NULL) {
    table <- dbQuoteIdentifier(con, table)
    fields <- createFields(con, fields, field.types, row.names)

    SQL(paste0(
        "CREATE ", if (temporary) " MULTISET VOLATILE ", "TABLE ", table, " (\n",
        "  ", paste(fields, collapse = ",\n  "), "\n)\n", if (temporary) " ON COMMIT PRESERVE ROWS"
        ))
  })


setMethod(
  "odbcConnectionTables",
  c("Teradata", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, table_type = NULL) {

    res <- callNextMethod()
    if ( !is.null(schema_name) ) {
      return(res)
    }

    # Also look through volatile tables if
    # not querying in a specific schema
    tempTableNames <- dbGetQuery(conn, "HELP VOLATILE TABLE")[["Table SQL Name"]]
    # If a name argument is supplied, subset the temp table names vector
    # to either an exact match, or if pattern value, to an approximate match
    if ( !is.null( name ) ) {
      if ( isPatternValue( name ) ) {
        name <- convertWildCards( name )
      }
      else {
        name <- paste0("^", name, "$")
      }
      tempTableNames <- tempTableNames[ grepl(name, tempTableNames) ]
    }

    navec <- rep( NA_character_, length( tempTableNames ) )
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

# SAP HANA ----------------------------------------------------------------

setClass("HDB", where = class_cache)

#' @rdname DBI-methods
setMethod("sqlCreateTable", "HDB",
  function(con, table, fields, row.names = NA, temporary = FALSE, ..., field.types = NULL) {
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

#' @rdname DBI-methods
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

# Spark SQL ----------------------------------------------------------------

# Simple class prototype to avoid messages about unknown classes from setMethod
setClass("Spark SQL", where = class_cache)

#' @details Databricks supports multiple catalogs.  On the other hand,
#' the default implementation of `odbcConnectionSchemas` which routes through
#' `SQLTables` is likely to enumerate the schemas in the currently active
#' catalog only.
#'
#' This implementation will respect the `catalog_name` arrgument.
#' @rdname odbcConnectionSchemas
#' @usage NULL
setMethod(
  "odbcConnectionSchemas",
  c("Spark SQL", "character"),
  function(conn, catalog_name) {
    res <- dbGetQuery(conn, paste0("SHOW SCHEMAS IN ", catalog_name))
    if (nrow(res)) {
      return(res$databaseName)
    }
    return(character())
  }
)

# DB2 ----------------------------------------------------------------

setClass("DB2/AIX64", where = class_cache)

#' @rdname DBI-methods
# Don't generate a usage because there's some buglet in R CMD check
# (probably because of the `/` in the class name) which flags a usage
# without corresponding alias
#' @usage NULL
setMethod("sqlCreateTable", "DB2/AIX64",
  function(con, table, fields, row.names = NA, temporary = FALSE, ..., field.types = NULL) {
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

#' SQL Server
#'
#' Details of SQL Server methods for odbc and DBI generics.
#'
#' @rdname SQLServer
#' @usage NULL
setClass("Microsoft SQL Server", where = class_cache)

#' @description
#' ## `dbUnquoteIdentifier()`
#'
#' `conn@quote` returns the quotation mark, but quotation marks and square
#' brackets can be used interchangeably for delimited identifiers.
#' (<https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers>).
#' This function strips the brackets first and then calls the DBI method to
#' strip the quotation marks.
#' @rdname SQLServer
#' @docType methods
#' @usage NULL
#' @keywords internal
setMethod("dbUnquoteIdentifier", c("Microsoft SQL Server", "SQL"),
  function(conn, x, ...) {
    x <- gsub("(\\[)([^\\.]+?)(\\])", "\\2", x)
    callNextMethod( conn, x, ... )
  }
)


#' @description
#' ## `isTempTable()`
#'
#' Local temp tables are stored as
#' `[tempdb].[dbo].[#name]_____[numeric identifier]`, so `isTempTable()`
#' returns `TRUE` if `catalog_name` is `"tempdb"` or `"%"`, or the
#' name starts with `"#"`.
#' @rdname SQLServer
#' @usage NULL
setMethod("isTempTable", c("Microsoft SQL Server", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, ...) {
    if (!is.null(catalog_name) &&
        catalog_name != "%" &&
        length(catalog_name) > 0 &&
        catalog_name != "tempdb") {
      return(FALSE)
    }

    grepl("^[#][^#]", name)
})

#' @rdname SQLServer
#' @usage NULL
setMethod(
  "isTempTable",
  c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    isTempTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)


#' @description
#' ## `dbExistsTable()`
#' The default implementation reports temporary tables as non-existent
#' since they live in a different catalog. This method provides a special
#' case for temporary tables, as identified by `isTempTable()`.
#' @rdname SQLServer
#' @docType methods
#' @usage NULL
setMethod(
  "dbExistsTable", c("Microsoft SQL Server", "character"),
  function(conn, name, ...) {
    stopifnot(length(name) == 1)
    if (isTempTable(conn, name, ... )) {
      name <- paste0(name, "\\_\\_\\_%")
      df <- odbcConnectionTables(
        conn,
        name,
        catalog_name = "tempdb",
        schema_name = "dbo"
      )
    } else {
      df <- odbcConnectionTables(conn, name = name, ...)
    }
    NROW(df) > 0
  })

#' @rdname SQLServer
#' @usage NULL
setMethod(
  "dbExistsTable", c("Microsoft SQL Server", "Id"),
  function(conn, name, ...) {
    dbExistsTable(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  })

#' @rdname SQLServer
#' @usage NULL
setMethod(
  "dbExistsTable", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    dbExistsTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  })

#' @rdname SQLServer
#' @description
#' ## `sqlCreateTable()`
#'
#' Warns if `temporary = TRUE` but the `name` does not conform to temp table
#' naming conventions (i.e. it doesn't start with `#`).
#' @usage NULL
setMethod("sqlCreateTable", "Microsoft SQL Server",
  function(con,
           table,
           fields,
           row.names = NA,
           temporary = FALSE,
           ...,
           field.types = NULL) {
    if (temporary && !isTempTable(con, table)) {
      warning("Temporary flag is set to true, but table name doesn't use # prefix")
    }
    temporary <- FALSE
    callNextMethod()
})
