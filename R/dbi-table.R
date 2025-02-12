#' @include dbi-connection.R
NULL

#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn An [OdbcConnection] object, produced by [DBI::dbConnect()].
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characters, not
#'   just any valid bare table name.
#' @param value A data.frame to write to the database.
#' @inheritParams DBI::sqlCreateTable
#' @examples
#' \dontrun{
#' library(DBI)
#' con <- dbConnect(odbc::odbc())
#' dbListTables(con)
#' dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' dbReadTable(con, "mtcars")
#'
#' dbListTables(con)
#' dbExistsTable(con, "mtcars")
#'
#' # A zero row data frame just creates a table definition.
#' dbWriteTable(con, "mtcars2", mtcars[0, ], temporary = TRUE)
#' dbReadTable(con, "mtcars2")
#'
#' dbDisconnect(con)
#' }
#' @name DBI-tables
NULL

odbc_write_table <- function(conn,
                             name,
                             value,
                             overwrite = FALSE,
                             append = FALSE,
                             temporary = FALSE,
                             row.names = NULL,
                             field.types = NULL,
                             batch_rows = getOption("odbc.batch_rows", NA),
                             ...) {
  call <- caller_env()
  check_bool(overwrite, call = call)
  check_bool(append, call = call)
  check_bool(temporary, call = call)
  check_number_whole(batch_rows, allow_na = TRUE, allow_null = TRUE, call = call)
  check_row.names(row.names, call = call)
  check_field.types(field.types, call = call)
  if (append && !is.null(field.types)) {
    cli::cli_abort(
      "Cannot specify {.arg field.types} with {.code append = TRUE}.",
      call = call
    )
  }
  if (overwrite && append) {
    cli::cli_abort(
      "{.arg overwrite} and {.arg append} cannot both be {.val TRUE}.",
      call = call
    )
  }

  found <- dbExistsTableForWrite(conn, name)
  if (found && !overwrite && !append) {
    cli::cli_abort(
      "Table {toString(name)} exists in database, and both overwrite and \\
       append are {.code FALSE}.",
      call = call
    )
  }
  if (found && overwrite) {
    dbRemoveTable(conn, name)
  }

  values <- sqlData(conn, row.names = row.names, value[, , drop = FALSE])
  if (!found || overwrite) {
    dbCreateTable(
      conn = conn,
      name = name,
      fields = values,
      field.types = field.types,
      row.names = NULL,
      temporary = temporary
    )
  }
  dbAppendTable(
    conn = conn,
    name = name,
    value = values,
    batch_rows = batch_rows,
    ...,
    row.names = NULL
  )
  invisible(TRUE)
}

#' @rdname DBI-tables
#' @inheritParams DBI::dbWriteTable
#' @param overwrite Allow overwriting the destination table. Cannot be
#'   `TRUE` if `append` is also `TRUE`.
#' @param append Allow appending to the destination table. Cannot be
#'   `TRUE` if `overwrite` is also `TRUE`.
#' @param batch_rows The number of rows to retrieve. Defaults to `NA`, which
#'   is set dynamically to the minimum of 1024 and the size of the input.
#'   Depending on the database, driver, dataset and free memory, setting this
#'   to a lower value may improve performance.
#' @export
setMethod("dbWriteTable", c("OdbcConnection", "character", "data.frame"),
  odbc_write_table
)

#' @rdname DBI-tables
#' @export
setMethod("dbWriteTable", c("OdbcConnection", "Id", "data.frame"),
  odbc_write_table
)

#' @rdname DBI-tables
#' @export
setMethod("dbWriteTable", c("OdbcConnection", "SQL", "data.frame"),
  odbc_write_table
)

#' @rdname DBI-tables
#' @inheritParams DBI::dbAppendTable
#' @inheritParams DBI::dbWriteTable
#' @export
setMethod("dbAppendTable", "OdbcConnection",
  function(conn, name, value,
           batch_rows = getOption("odbc.batch_rows", NA),
           ..., row.names = NULL) {
    if (!is.null(row.names)) {
      cli::cli_abort(
        "{.arg row.names} must be {.code NULL}, not \\
         {.obj_type_friendly {row.names}}."
      )
    }

    fieldDetails <- tryCatch({
      details <- odbcConnectionColumns_(conn, name, exact = TRUE)
      details$param_index <- match(details$name, colnames(value))
      details[!is.na(details$param_index) & !is.na(details$data_type), ]
    },
    error = function(e) {
      return(NULL)
    })

    if (nrow(value) > 0) {
      name <- dbQuoteIdentifier(conn, name)
      fields <- dbQuoteIdentifier(conn, colnames(value))
      nparam <- length(fields)
      params <- rep("?", nparam)

      sql <- paste0(
        "INSERT INTO ", name, " (", paste0(fields, collapse = ", "), ")\n",
        "VALUES (", paste0(params, collapse = ", "), ")"
      )
      rs <- OdbcResult(conn, sql)

      if (!is.null(fieldDetails) && nrow(fieldDetails) <= nparam) {
        result_describe_parameters(rs@ptr, fieldDetails)
      }

      values <- sqlData(conn, row.names = row.names, value[, , drop = FALSE])
      if (is.na(batch_rows)) {
        batch_rows <- NROW(value)
        if (batch_rows == 0) {
          batch_rows <- 1
        }
        batch_rows <- min(1024, batch_rows)
      }
      batch_rows <- parse_size(batch_rows)
      tryCatch(
        result_insert_dataframe(rs@ptr, values, batch_rows),
        finally = dbClearResult(rs)
      )
    }

    invisible(NA_real_)
  })

#' @rdname DBI-methods
#' @export
setMethod("sqlData", "OdbcConnection",
  function(con, value, row.names = NA, ...) {

    chk <- attr(value, ".odbc.transformed", exact = TRUE)
    if (isTRUE(chk)) return(value)

    value <- sqlRownamesToColumn(value, row.names)

    # Convert POSIXlt to POSIXct
    is_POSIXlt <- vapply(value, function(x) is.object(x) && (is(x, "POSIXlt")), logical(1))
    value[is_POSIXlt] <- lapply(value[is_POSIXlt], as.POSIXct)

    # Convert data.table::IDate to Date
    is_IDate <- vapply(value, function(x) is.object(x) && (is(x, "IDate")), logical(1))
    value[is_IDate] <- lapply(value[is_IDate], as.Date)

    # C code takes care of atomic vectors, dates, date times, and blobs just need to coerce other objects
    is_object <- vapply(value, function(x) is.object(x) && !(is(x, "POSIXct") || is(x, "Date") || is_blob(x) || is(x, "difftime")), logical(1))
    value[is_object] <- lapply(value[is_object], as.character)

    if (nzchar(con@encoding)) {
      is_character <- vapply(value, is.character, logical(1))
      value[is_character] <- lapply(value[is_character], enc2iconv, to = con@encoding)
    }

    attr(value, ".odbc.transformed") <- TRUE
    value
  }
)

#' @rdname DBI-tables
#' @inheritParams DBI::sqlCreateTable
#' @param field.types Additional field types used to override derived types.
#' @export
setMethod("sqlCreateTable", "OdbcConnection",
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
      "CREATE ", if (temporary) "TEMPORARY ", "TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "), "\n)\n"
    ))
  }
)

# Helper function useful for defining custom sqlCreateTable methods.
createFields <- function(con, fields, field.types, row.names) {
  if (is.data.frame(fields)) {
    fields <- sqlRownamesToColumn(fields, row.names)
    fields <- DBI::dbDataType(con, fields)
  }
  if (!is.null(field.types)) {
    is_field <- names(field.types) %in% names(fields)
    if (!all(is_field)) {
      warning(
        sprintf(
          "Some columns in `field.types` not in the input, missing columns:\n%s",
          paste0("  - '", names(field.types)[!is_field], "'", collapse = "\n")
        ),
        call. = FALSE, immediate. = TRUE
      )
    }

    fields[names(field.types)] <- field.types
  }

  field_names <- dbQuoteIdentifier(con, names(fields))
  field_types <- unname(fields)
  paste0(field_names, " ", field_types)
}

#' @rdname OdbcConnection
#' @inheritParams DBI::dbListFields
#' @export
setMethod("dbListFields", c("OdbcConnection", "Id"),
  function(conn, name, ...) {
    dbListFields(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbListFields
#' @export
setMethod("dbListFields", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    dbListFields(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbListFields
#' @param catalog_name Catalog where table is located.
#' @param schema_name Schema where table is located.
#' @param column_name The name of the column to return, the default returns all columns.
#' @export
setMethod("dbListFields", c("OdbcConnection", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           ...) {
    check_string(name)
    check_string(catalog_name, allow_null = TRUE)
    check_string(schema_name, allow_null = TRUE)
    check_string(column_name, allow_null = TRUE)

    cols <- odbcConnectionColumns_(
      conn,
      name = name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name,
      exact = TRUE
    )
    cols[["name"]]
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod("dbExistsTable", c("OdbcConnection", "Id"),
  function(conn, name, ...) {
    dbExistsTable(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod("dbExistsTable", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    dbExistsTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod("dbExistsTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    check_string(name)
    df <- odbcConnectionTables(conn, name = name, ..., exact = TRUE)
    NROW(df) > 0
  }
)


#' @rdname OdbcConnection
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod("dbRemoveTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbExecute(conn, paste("DROP TABLE ", name))
    on_connection_updated(conn, name)
    invisible(TRUE)
  }
)
