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

sql_create_table_teradata <- function(
  con, table, fields, row.names = NA, temporary = FALSE,
  field.types = NULL,
  # teradata specific arguments
  index = NA,
  partition_by = NA,
  ...) {

  table <- dbQuoteIdentifier(con, table)
  fields <- createFields(con, fields, field.types, row.names)

  DBI::SQL(paste0(
    "CREATE MULTISET ",
    if (temporary) "VOLATILE ",
    "TABLE ", table,
    if(temporary) ", no log", " (\n",
    "  ", paste(fields, collapse = ",\n  "), "\n)\n",
    if(!missing(index)) paste0("PRIMARY INDEX ( ", paste(index, collapse = ", "), " ) "), "\n",
    if(!missing(partition_by)) paste0(partition_by, "\n"),
    if (temporary) "ON COMMIT PRESERVE ROWS"
  ))
}


#' @rdname odbc-tables
#' @param index (teradata specific) character vector of columns to put in the `PRIMARY INDEX` clause.
#' @param partition_by (teradata specific) character vector of length 1, that is put between
#'                     `PRIMARY INDEX` and before `ON COMMIT PRESERVE ROWS` clause.
#'                     It should start with "PARTITION BY".
#'
#' @export
setMethod(
  "sqlCreateTable", c("Teradata"),
  sql_create_table_teradata
)

# check if table is "temporary" (has no schema specified)
teradata_is_temporary_table_name <- function(table_name){
  if (is(table_name, "Id")){
    !("schema" %in% names(table_name@name))
  } else if(is(table_name, "SQL")){
    !grepl("\\.", table_name)
  } else if(is.character(table_name)){
    !grepl("\\.", table_name)
  } else{
    stop("table_name must be DBI::Id, character or SQL", call. = FALSE)
  }
}

teradata_exists_table <- function(conn, name, temporary = NULL, schema_name, ...) {
  stopifnot(length(name) == 1)

  if(is.null(temporary)){
    if(missing(schema_name)){
      temporary <- teradata_is_temporary_table_name(name)
    } else {
      temporary <- FALSE
    }
  }

  # significantly faster to only look in volatile tables if looking for
  # volatile tables.
  if(temporary){
    name %in% DBI::dbGetQuery(conn, "HELP VOLATILE TABLE")[["Table SQL Name"]]
  } else {
    name %in% DBI::dbListTables(conn, table_name = name, schema_name = schema_name, ...)
  }
}

#' Teradata version of dbExistsTable
#'
#' @inheritParams DBI::dbExistsTable
#' @param temporary (boolean, default to NULL) if TRUE, look only into temporary table.
#'                  Setting `temporary` to FALSE allow to look for a table name in multiple schemas.
#'                  `temporary` is ignored if an object of type `DBI::Id` is passed
#'                  to `name`.
#' @param ... Other arguments are passed to DBI::dbListTables
#'
#' @export
#' @rdname dbExistsTable_teradata
setMethod(
  "dbExistsTable", c("Teradata", "character"),
  teradata_exists_table
)

#' @export
#' @rdname dbExistsTable_teradata
setMethod(
  "dbExistsTable", c("Teradata", "Id"),
  function(conn, name, temporary = NULL, ...){
    teradata_exists_table(
      conn,
      name = id_field(name, "table"),
      temporary = teradata_is_temporary_table_name(name),
      schema_name = id_field(name, "schema"),
      ...
    )
  }
)

#' @export
#' @rdname dbExistsTable_teradata
setMethod(
  "dbExistsTable", c("Teradata", "SQL"),
  function(conn, name, ...){

    name_vec <- strsplit(name, ".", fixed = TRUE)[[1]]
    if(length(name_vec) > 2){
      stop("More than 1 dot found in argument `name`,
           cannot identify schema and table in argument `name`.")
    }
    teradata_exists_table(
      conn,
      name = name_vec[2],
      temporary = FALSE,
      schema_name = name_vec[1],
      ...
    )
  }
)


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
