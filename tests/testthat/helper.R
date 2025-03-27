test_connection_string <- function(db) {
  testthat::skip_on_cran()

  var <- paste0("ODBC_CS_", db)
  cs <- Sys.getenv(var)
  if (cs == "") {
    skip(paste0("env var '", var, "' not set"))
  }
  list(.connection_string = cs)
}

test_con <- function(db, ...) {
  dbConnect(
    odbc::odbc(),
    .connection_string = test_connection_string(db),
    ...
  )
}

local_table <- function(con, name, df, ..., envir = parent.frame()) {
  dbWriteTable(con, name, df, ...)
  withr::defer(dbRemoveTable(con, name), envir = envir)

  name
}

skip_if_no_drivers <- function() {
  if (nrow(odbcListDrivers()) == 0) {
    skip("No drivers installed")
  }
}

skip_if_no_unixodbc <- function() {
  if (!is_windows() && length(locate_install_unixodbc()) == 0) {
    skip("No unixodbc installation found.")
  }
}

#' Test round tripping a simple table
#'
#' This tests all the supported data types, including missing values. It first
#' writes them to the database, then reads them back and verifies the data is
#' identical to the original.
#'
#' This function is not exported and should only be used during tests and as a
#' sanity check when writing new `odbcDataType()` methods.
#'
#' @param con An established DBI connection.
#' @param columns Table columns to exclude (default) or include, dependent on
#' the value of `invert`. One of `datetime`, `date`, `binary`,
#' `integer`, `double`, `character`, `logical`.
#' @param invert If `TRUE`, change the definition of columns to be exclusive,
#' rather than inclusive.
#' @param force_sorted If `TRUE`, a sorted `id` column is added to the sent
#' data, and the received data is sorted by this column before doing the
#' comparison. This is necessary for some databases that do not preserve row
#' order.
#' @examples
#' \dontrun{
#' test_roundtrip(con)
#'
#' # exclude a few columns
#' test_roundtrip(con, c("integer", "double"))
#'
#' # Only test a specific column
#' test_roundtrip(con, "integer", invert = FALSE)
#' }
test_roundtrip <- function(con, columns = "", invert = TRUE, force_sorted = FALSE) {
  dbms <- dbGetInfo(con)$dbms.name
  res <- list()
  testthat::test_that(paste0("[", dbms, "] round tripping data.frames works"), {
    # on.exit(try(DBI::dbRemoveTable(con, "test_table"), silent = TRUE))
    set.seed(42)

    iris <- datasets::iris

    # We can't use the data.frame constructor directly as list columns don't work there.
    sent <- list(

      # We always return strings as factors
      # factor = iris$Species,
      datetime = as.POSIXct(as.numeric(iris$Petal.Length * 10), origin = "2016-01-01", tz = "UTC"),
      date = as.Date(iris$Sepal.Width * 100, origin = Sys.time()),
      time = hms::hms(seconds = sample.int(24 * 60 * 60, NROW(iris))),
      binary = blob::as_blob(lapply(seq_len(NROW(iris)), function(x) as.raw(sample(0:100, size = sample(0:25, 1))))),
      integer = as.integer(iris$Petal.Width * 100),
      double = iris$Sepal.Length,
      character = as.character(iris$Species),
      logical = sample(c(TRUE, FALSE), size = nrow(iris), replace = T)
    )
    attributes(sent) <- list(names = names(sent), row.names = c(NA_integer_, -length(sent[[1]])), class = "data.frame")

    # Add a proportion of NA values to a data frame
    add_na <- function(x, p = .1) {
      is.na(x) <- stats::runif(length(x)) < p
      x
    }
    sent[] <- lapply(sent, add_na, p = .1)
    if (isTRUE(invert)) {
      sent <- sent[, !names(sent) %in% columns]
    } else {
      sent <- sent[, names(sent) %in% columns]
    }
    if (force_sorted) sent$id <- seq_len(NROW(iris))

    DBI::dbWriteTable(con, "test_table", sent, overwrite = TRUE)
    received <- DBI::dbReadTable(con, "test_table")
    if (force_sorted) received <- received[order(received$id), ]
    row.names(received) <- NULL
    testthat::expect_equal(sent, received)
    res <<- list(sent = sent, received = received)
  })
  invisible(res)
}
