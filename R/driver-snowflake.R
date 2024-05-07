#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Snowflake", contains = "OdbcConnection")

#' getCatalogSchema
#'
#' Internal, Snowflake specific method that will return a list
#' where `catalog_name` and `schema_name` are either the arguments
#' passed by the user ( if not null ), or if null, the CURRENT
#' database ( or schema, respectively ).
#' @noRd
getCatalogSchema <- function(conn, catalog_name = NULL, schema_name = NULL) {
  if(is.null(catalog_name) || is.null(schema_name)) {
    res <- dbGetQuery(conn, "SELECT CURRENT_DATABASE() AS CAT, CURRENT_SCHEMA() AS SCH")
    if(is.null(catalog_name) && !is.na(res$CAT)) {
      catalog_name <- res$CAT
    }
    if(is.null(schema_name) && !is.na(res$SCH)) {
      schema_name <- res$SCH
    }
  }
  return(list(catalog_name = catalog_name, schema_name = schema_name))
}

#' Connecting to Snowflake via ODBC
#'
#' @description
#' ## `odbcConnectionColumns()`
#'
#' If the catalog, or the schema arguments are NULL, attempt to infer
#' by querying for CURRENT_DATABASE() and CURRENT_SCHEMA().  We do this
#' to aid with performance, as the SQLColumns method is more performant
#' when restricted to a particular DB/schema.
#' @inheritParams DBI::dbListFields
#' @rdname Snowflake
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Snowflake", "character"),
  function(conn,
           name,
           ...,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
    catSchema <- getCatalogSchema(conn, catalog_name, schema_name)

    callNextMethod(conn = conn, name = name, ..., catalog_name = catSchema$catalog_name,
      schema_name = catSchema$schema_name, column_name = column_name, exact = exact)
  }
)

#' @rdname Snowflake
setMethod("dbExistsTableForWrite", c("Snowflake", "character"),
  function(conn, name, ...,
           catalog_name = NULL, schema_name = NULL) {
    catSchema <- getCatalogSchema(conn, catalog_name, schema_name)
    catalog_name <- catSchema$catalog_name
    schema_name <- catSchema$schema_name

    callNextMethod(conn = conn, name = name, ...,
      catalog_name = catalog_name, schema_name = schema_name)
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
