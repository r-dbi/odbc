
# Microsoft SQL Server ---------------------------------------------------------

#' SQL Server
#'
#' Details of SQL Server methods for odbc and DBI generics.
#'
#' @rdname SQLServer
#' @export
setClass("Microsoft SQL Server", contains = "OdbcConnection")

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
    callNextMethod(conn, x, ...)
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
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("isTempTable", c("Microsoft SQL Server", "SQL"),
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
setMethod("dbExistsTable", c("Microsoft SQL Server", "character"),
  function(conn, name, ...) {
    check_string(name)
    if (isTempTable(conn, name, ...)) {
      query <- paste0("SELECT OBJECT_ID('tempdb..", name, "')")
      !is.na(dbGetQuery(conn, query)[[1]])
    } else {
      df <- odbcConnectionTables(conn, name = name, ...)
      NROW(df) > 0
    }
  }
)

#' @description
#' ## `dbListTables()`
#' The default implementation reports temporary tables as non-existent
#' when a `catalog_name` isn't supplied since they live in a different catalog.
#' This method provides a special case for temporary tables.
#' @rdname SQLServer
#' @usage NULL
setMethod("dbListTables", "Microsoft SQL Server",
  function(conn,
           catalog_name = NULL,
           schema_name = NULL,
           table_name = NULL,
           table_type = NULL,
           ...) {
    check_string(catalog_name, allow_null = TRUE)
    check_string(schema_name, allow_null = TRUE)
    check_string(table_name, allow_null = TRUE)
    check_string(table_type, allow_null = TRUE)

    res <- callNextMethod()

    if (is.null(catalog_name) && is.null(schema_name)) {
      res_temp <- callNextMethod(
        conn = conn,
        catalog_name = "tempdb",
        schema_name = "dbo"
      )

      res <- c(res, res_temp)
    }

    res
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("dbExistsTable", c("Microsoft SQL Server", "Id"),
  function(conn, name, ...) {
    dbExistsTable(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("dbExistsTable", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    dbExistsTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

#' @description
#' ## `odbcConnectionSchemas`
#'
#' Method for an internal function. Calls catalog-specific `sp_tables` to make
#' sure we list the schemas in the appropriate database/catalog.
#' @rdname SQLServer
#' @usage NULL
setMethod(
  "odbcConnectionSchemas", "Microsoft SQL Server",
  function(conn, catalog_name = NULL) {

    if (is.null(catalog_name) || !nchar(catalog_name)) {
      return(callNextMethod())
    }
    sproc <- paste(
      dbQuoteIdentifier(conn, catalog_name), "dbo.sp_tables", sep = ".")

    res <- dbGetQuery(conn, paste0(
        "EXEC ", sproc, " ",
        "@table_name = '', ",
        "@table_owner = '%', ",
        "@table_qualifier = ''"
    ))
    res$TABLE_OWNER
  }
)

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
    check_bool(temporary)
    check_row.names(row.names)
    check_field.types(field.types)
    if (temporary && !isTempTable(con, table)) {
      cli::cli_warn(
        "{.arg temporary} is {.code TRUE}, but table name doesn't use # prefix."
      )
    }
    temporary <- FALSE
    callNextMethod()
  }
)

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Microsoft SQL Server",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = varchar(obj),
      datetime = "DATETIME",
      date = "DATE",
      time = "TIME",
      binary = varbinary(obj),
      integer = "INT",
      int64 = "BIGINT",
      double = "FLOAT",
      character = varchar(obj),
      logical = "BIT",
      list = varchar(obj),
      stop("Unsupported type", call. = FALSE)
    )
  }
)

#' @description
#' ## `odbcConnectionColumns_()`
#'
#' If temp table, query the database for the
#' actual table name.
#' @rdname SQLServer
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Microsoft SQL Server", "character"),
  function(conn,
           name,
           ...,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
    if (exact &&
      isTempTable(conn, name, catalog_name, schema_name, column_name, exact)) {
      catalog_name <- "tempdb"
      schema_name <- "dbo"
      query <- paste0("SELECT name FROM tempdb.sys.tables WHERE ",
        "object_id = OBJECT_ID('tempdb..", name, "')")
      name <- dbGetQuery(conn, query)[[1]]
    }

    callNextMethod(
      conn = conn,
      name = name,
      ...,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name,
      exact = exact
    )
  }
)

#' @description
#' ## `odbcConnectionColumns_()`
#'
#' Copied over from odbc-connection to avoid S4 dispatch NOTEs.
#' @rdname SQLServer
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    odbcConnectionColumns_(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)
