#' @include dbi-connection.R
#' @include odbc-connection.R
NULL

#' Oracle
#'
#' Details of Oracle methods for odbc and DBI generics.
#'
#' @export
#' @rdname Oracle
#' @keywords internal
setClass("Oracle", contains = "OdbcConnection")

#' @rdname Oracle
setMethod("sqlCreateTable", "Oracle",
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
      "CREATE ", if (temporary) " GLOBAL TEMPORARY ", "TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "), "\n)\n",
      if (temporary) " ON COMMIT PRESERVE ROWS"
    ))
  }
)

#' @rdname Oracle
#' @description
#' ## `odbcConnectionTables()`
#'
#' Method for an internal function that otherwise relies on the `SQLTables`
#' ODBC API. While this method is much faster than the OEM implementation, it
#' does not look through synonyms.
setMethod("odbcConnectionTables", c("Oracle", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           table_type = NULL,
           exact = FALSE) {
    qTable <- getSelector("object_name", name, exact)
    if (is.null(schema_name)) {
      query <- paste0(
        " SELECT null AS \"table_catalog\", USER AS \"table_schema\", object_name AS \"table_name\", object_type AS \"table_type\", null AS \"table_remarks\"",
        " FROM user_objects ",
        " WHERE 1 = 1 ", qTable,
        " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) "
      )
    } else {
      qSchema <- getSelector("owner", schema_name, exact)
      query <- paste0(
        " SELECT null AS \"table_catalog\", owner AS \"table_schema\", object_name AS \"table_name\", object_type AS \"table_type\", null AS \"table_remarks\"",
        " FROM all_objects ",
        " WHERE 1 = 1 ", qSchema, qTable,
        " AND ( object_type = 'TABLE' OR object_type = 'VIEW' ) "
      )
    }

    dbGetQuery(conn, query)
  }
)

#' @rdname Oracle
#' @description
#' ## `odbcConnectionColumns()`
#'
#' Query, rather than use `SQLColumns` ODBC API, since we bind a `BIGINT` to
#' one of the column results and Oracle's OEM driver can't handle it.
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Oracle", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
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
      decode(nullable, 'Y', 1, 'N', 0) AS \"nullable\""
    )
    qTable <- getSelector("table_name", name, exact)
    if (is.null(schema_name)) {
      baseSelect <- gsub("owner AS \"schema_name\"", paste0("'", conn@info$username, "' AS \"schema_name\""), baseSelect)
      query <- paste0(
        baseSelect,
        " FROM user_tab_columns ",
        " WHERE 1 = 1 ", qTable
      )
    } else {
      qSchema <- getSelector("owner", schema_name, exact)
      query <- paste0(
        baseSelect,
        " FROM all_tab_columns ",
        " WHERE 1 = 1 ", qSchema, qTable
      )
    }

    dbGetQuery(conn, query)
  }
)

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Oracle",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "VARCHAR2(255)",

      # No native oracle type for time
      time = "VARCHAR2(255)",
      date = "DATE",
      datetime = "TIMESTAMP",
      binary = "BLOB",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "BINARY_DOUBLE",
      character = "VARCHAR2(255)",
      logical = "DECIMAL",
      list = "VARCHAR2(255)",
      stop("Unsupported type", call. = FALSE)
    )
  }
)

