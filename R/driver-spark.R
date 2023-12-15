#' @export
#' @rdname DBI-classes
setClass("Spark SQL", contains = "OdbcConnection")

#' @details Databricks supports multiple catalogs.  On the other hand,
#' the default implementation of `odbcConnectionSchemas` which routes through
#' `SQLTables` is likely to enumerate the schemas in the currently active
#' catalog only.
#'
#' This implementation will respect the `catalog_name` arrgument.
#' @rdname odbcConnectionSchemas
#' @usage NULL
setMethod("odbcConnectionSchemas", c("Spark SQL", "character"),
  function(conn, catalog_name) {
    res <- dbGetQuery(conn, paste0("SHOW SCHEMAS IN ", catalog_name))
    if (nrow(res)) {
      return(res$databaseName)
    }
    return(character())
  }
)
