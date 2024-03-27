
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
    stopifnot(length(name) == 1)
    if (isTempTable(conn, name, ...)) {
      query <- paste0("SELECT OBJECT_ID('tempdb..", name, "')")
      return(!is.na(dbGetQuery(conn, query)[[1]]))
    }
    df <- odbcConnectionTables(conn, name = name, ...)
    synonyms <- dbGetQuery(conn, synonyms_query(conn, ...))
    NROW(df) > 0 || name %in% synonyms$name
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
    res <- callNextMethod()

    if (is.null(catalog_name) && is.null(schema_name)) {
      res_temp <- callNextMethod(
        conn = conn,
        catalog_name = "tempdb",
        schema_name = "dbo"
      )

      res <- c(res, res_temp)
    }

    synonyms <- dbGetQuery(conn, synonyms_query(conn, catalog_name, schema_name))

    c(res, synonyms$name)
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
    if (temporary && !isTempTable(con, table)) {
      warning("Temporary flag is set to true, but table name doesn't use # prefix")
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

#' @rdname SQLServer
#' @description
#' ## `odbcListObjects()`
#'
#' This method makes tables that are synonyms visible in the Connections pane.
# See (#221).
#' @usage NULL
#' @export
`odbcListObjects.Microsoft SQL Server` <- function(connection,
                                                   catalog = NULL,
                                                   schema = NULL,
                                                   name = NULL,
                                                   type = NULL,
                                                   ...) {
  objects <- NextMethod(
    object = connection,
    catalog = catalog,
    schema = schema,
    name = name,
    type = type,
    ...
  )

  synonyms <- dbGetQuery(connection, synonyms_query(connection, catalog, schema))

  if (!is.null(name)) {
    synonyms <- synonyms[synonyms$name == name, , drop = FALSE]
  }

  rbind(
    objects,
    data.frame(name = synonyms$name, type = rep("table", length(synonyms$name)))
  )
}

synonyms_query <- function(conn, catalog_name = NULL, schema_name = NULL) {
  res <- "SELECT
            catalog = DB.name,
            [schema] = Sch.name,
            name   = Syn.name
          FROM sys.synonyms          AS Syn
            INNER JOIN sys.schemas AS Sch
              ON Sch.schema_id = Syn.schema_id
            INNER JOIN sys.databases AS DB
              ON Sch.principal_id = DB.database_id"

  has_catalog <- !is.null(catalog_name)
  has_schema <- !is.null(schema_name)
  if (!has_catalog & !has_schema) {
    return(paste0(res, filter_is_table))
  }

  if (has_catalog & has_schema) {
    res <- paste0(res, " WHERE DB.name = '", catalog_name, "' AND Sch.name = '", schema_name, "'")
  } else if (has_catalog) {
    res <- paste0(res, " WHERE DB.name = '", catalog_name, "'")
  } else if (has_schema) {
    res <- paste0(res, " WHERE Sch.name = '", schema_name, "'")
  }

  paste0(res, filter_is_table)
}

filter_is_table <- " AND OBJECTPROPERTY(Object_ID(Syn.base_object_name), 'IsTable') = 1;"
