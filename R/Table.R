#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn a \code{\linkS4class{OdbcConnection}} object, produced by
#'   [DBI::dbConnect()]
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
#' @name odbc-tables
NULL

#' @rdname odbc-tables
#' @inheritParams DBI::dbWriteTable
#' @param overwrite Allow overwriting the destination table. Cannot be
#'   `TRUE` if `append` is also `TRUE`.
#' @param append Allow appending to the destination table. Cannot be
#'   `TRUE` if `overwrite` is also `TRUE`.
#' @export
setMethod(
  "dbWriteTable", c("OdbcConnection", "character", "data.frame"),
  function(conn, name, value, dataTypes = NULL, overwrite=FALSE, append=FALSE, temporary = FALSE,
    row.names = NA, fieldTypes = NULL, ...) {

    if (overwrite && append)
      stop("overwrite and append cannot both be TRUE", call. = FALSE)

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    values <- sqlData(conn, row.names = row.names, value[, , drop = FALSE])

    if (!found || overwrite) {
      sql <- sqlCreateTable(conn, name, values, types, fieldTypes = fieldTypes, row.names = FALSE, temporary = temporary)
      dbExecute(conn, sql)
    }

    if (nrow(value) > 0) {

      name <- dbQuoteIdentifier(conn, name)
      fields <- dbQuoteIdentifier(conn, names(values))
      params <- rep("?", length(fields))

      sql <- paste0(
        "INSERT INTO ", name, " (", paste0(fields, collapse = ", "), ")\n",
        "VALUES (", paste0(params, collapse = ", "), ")"
        )
      rs <- OdbcResult(conn, sql)

      tryCatch(
        result_insert_dataframe(rs@ptr, values),
        finally = dbClearResult(rs)
        )
    }

    invisible(TRUE)
  }
)

##' @rdname odbc-tables
##' @inheritParams DBI::dbReadTable
##' @export
setMethod("sqlData", "OdbcConnection", function(con, value, row.names = NA, ...) {
  value <- sqlRownamesToColumn(value, row.names)

  # Convert POSIXlt to POSIXct
  is_POSIXlt <- vapply(value, function(x) is.object(x) && (is(x, "POSIXlt")), logical(1))
  value[is_POSIXlt] <- lapply(value[is_POSIXlt], as.POSIXct)

  # C code takes care of atomic vectors, dates, date times, and blobs just need to coerce other objects
  is_object <- vapply(value, function(x) is.object(x) && !(is(x, "POSIXct") || is(x, "Date") || is(x, "blob") || is(x, "difftime")), logical(1))
  value[is_object] <- lapply(value[is_object], as.character)

  if (nzchar(con@encoding)) {
    is_character <- vapply(value, is.character, logical(1))
    value[is_character] <- lapply(value[is_character], enc2iconv, to = con@encoding)
  }

  value
})

##' @rdname odbc-tables
##' @inheritParams DBI::sqlCreateTable
##' @param fieldTypes Additional field types used to override derived types.
##' @export
setMethod("sqlCreateTable", "OdbcConnection",
  function(con, table, fields, fieldTypes = NULL, row.names = NA, temporary = FALSE, ...) {
    table <- dbQuoteIdentifier(con, table)

    if (is.data.frame(fields)) {
      fields <- sqlRownamesToColumn(fields, row.names)
      fields <- vapply(fields, function(x) DBI::dbDataType(con, x), character(1))
    }
    if (!is.null(fieldTypes)) {
      fields[names(fieldTypes)] <- fieldTypes
    }

    field_names <- dbQuoteIdentifier(con, names(fields))
    field_types <- unname(fields)
    fields <- paste0(field_names, " ", field_types)

    SQL(paste0(
      "CREATE ", if (temporary) "TEMPORARY ", "TABLE ", table, " (\n",
      "  ", paste(fields, collapse = ",\n  "), "\n)\n"
    ))
  }
)
