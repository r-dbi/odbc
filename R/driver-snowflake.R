#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Snowflake", contains = "OdbcConnection")

#' @rdname Snowflake
#' @description
#' ## `odbcConnectionColumns()`
#'
#' If the catalog, or the schema arguments are NULL, attempt to infer
#' by querying for CURRENT_DATABASE() and CURRENT_SCHEMA().  We do this
#' to aid with performance, as the SQLColumns method is more performant
#' when restricted to a particular DB/schema.
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Snowflake", "character"),
  function(conn,
           name,
           ...,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
    if(is.null(catalog_name) || is.null(schema_name)) {
      res <- dbGetQuery(conn, "SELECT CURRENT_DATABASE() AS CAT, CURRENT_SCHEMA() AS SCH")
      if(is.null(catalog_name) && !is.na(res$CAT[1])) {
        catalog_name <- res$CAT[1]
      }
      if(is.null(schema_name) && !is.na(res$SCH[1])) {
        schema_name <- res$SCH[1]
      }
    }
    callNextMethod(conn = conn, name = name, ..., catalog_name = catalog_name,
      schema_name = schema_name, column_name = column_name, exact = exact)
  }
)

#' If the catalog, or the schema arguments are NULL, attempt to infer
#' by querying for CURRENT_DATABASE() and CURRENT_SCHEMA().  We do this
#' to aid with performance, as the SQLTables method is more performant
#' when restricted to a particular DB/schema.
#' @rdname Snowflake
setMethod("dbExistsTableForWrite", c("Snowflake", "character"),
  function(conn, name, ...) {
    args <- compact(list(...))
    if (is.null(args$catalog_name) || is.null(args$schema_name)) {
      res <- dbGetQuery(conn, "SELECT CURRENT_DATABASE() AS CATALOG, CURRENT_SCHEMA() AS SCHEMA")
      if(is.null(args$catalog_name) && !is.na(res$CATALOG[1])) {
        args$catalog_name <- res$CATALOG[1]
      }
      if(is.null(args$schema_name) && !is.na(res$SCHEMA[1])) {
        args$schema_name <- res$SCHEMA[1]
      }
    }

    do.call(callNextMethod, c(list(conn = conn, name = name), args))
  }
)

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Snowflake",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "VARCHAR",
      datetime = "TIMESTAMP",
      date = "DATE",
      time = "TIME",
      binary = "BINARY",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "FLOAT",
      character = "VARCHAR",
      logical = "BOOLEAN",
      list = "VARCHAR",
      stop("Unsupported type", call. = FALSE)
    )
  }
)
