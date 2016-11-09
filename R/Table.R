#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn a \code{\linkS4class{OdbconnectConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characters, not
#'   just any valid bare table name.
#' @param value A data.frame to write to the database.
#' @inheritParams DBI::sqlCreateTable
#' @examples
#' \dontrun{
#' library(DBI)
#' con <- dbConnect(odbconnect::odbconnect())
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
#' @name odbconnect-tables
NULL

#' @rdname odbconnect-tables
#' @inheritParams DBI::dbWriteTable
#' @param overwrite Allow overwriting the destination table. Cannot be
#'   \code{TRUE} if \code{append} is also \code{TRUE}.
#' @param append Allow appending to the destination table. Cannot be
#'   \code{TRUE} if \code{overwrite} is also \code{TRUE}.
#' @export
setMethod(
  "dbWriteTable", c("OdbconnectConnection", "character", "data.frame"),
  function(conn, name, value, overwrite=FALSE, append=FALSE, temporary = FALSE,
    ...) {

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

    if (!found && append) {
      stop("Table ", name, " does not exist", call. = FALSE)
    }

    values <- sqlData(conn, value[, , drop = FALSE])

    if (!found || overwrite) {
      sql <- sqlCreateTable(conn, name, values, temporary = temporary)
      dbGetQuery(conn, sql)
    }

    if (nrow(value) > 0) {

      name <- dbQuoteIdentifier(conn, name)
      fields <- dbQuoteIdentifier(conn, names(values))
      params <- rep("?", length(fields))

      sql <- paste0(
        "INSERT INTO ", name, " (", paste0(fields, collapse = ", "), ")\n",
        "VALUES (", paste0(params, collapse = ", "), ")"
        )
      rs <- OdbconnectResult(conn, sql)

      tryCatch(
        result_insert_dataframe(rs@ptr, values),
        finally = dbClearResult(rs)
        )
    }

    invisible(TRUE)
  }
)

##' @rdname odbconnect-tables
##' @inheritParams DBI::dbReadTable
##' @export
setMethod("sqlData", "OdbconnectConnection", function(con, value, row.names = NA, ...) {
  value <- sqlRownamesToColumn(value, row.names)

  # Convert POSIXlt to POSIXct
  is_POSIXlt <- vapply(value, function(x) is.object(x) && (is(x, "POSIXlt")), logical(1))
  value[is_POSIXlt] <- lapply(value[is_POSIXlt], as.POSIXct)

  # C code takes care of atomic vectors, dates, date times, and blobs just need to coerce other objects
  is_object <- vapply(value, function(x) is.object(x) && !(is(x, "POSIXct") || is(x, "Date") || is(x, "blob")), logical(1))
  value[is_object] <- lapply(value[is_object], as.character)

  value
})


#' @rdname odbconnect-tables
#' @inheritParams DBI::dbReadTable
#' @export
setMethod(
  "dbReadTable", c("OdbconnectConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("SELECT * FROM ", name))
  })
