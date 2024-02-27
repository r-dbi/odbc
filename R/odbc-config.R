#' List locations of ODBC configuration files
#'
#' @description
#' On MacOS and Linux, odbc uses the unixODBC driver manager to manage
#' information about driver and data sources. This helper returns the filepaths
#' where the driver manager will look for that information.
#'
#' This function is a wrapper around the command line call `odbcinst -j`.
#'
#' Windows does not use `.ini` configuration files; this function will return a
#' 0-length vector on Windows.
#'
#' @seealso
#' The [odbcListDrivers()] and [odbcListDataSources()] helpers return
#' information on the contents of `odbcinst.ini` and `odbc.ini` files,
#' respectively.
#'
#' Learn more about unixODBC and the `odbcinst` utility
#' [here](https://www.unixodbc.org/odbcinst.html).
#'
#' @examplesIf FALSE
#' configs <- odbcListConfig()
#'
#' file.edit(configs[1])
#' @export
odbcListConfig <- function() {
  if (is_windows()) {
    return(character(0))
  }

  if (!has_unixodbc()) {
    abort(
      c("The unixODBC driver manager is not available. ",
        "Please install and try again.")
    )
  }

  res <- system("odbcinst -j", intern = TRUE)
  res <- res[grepl("\\.ini", res)]
  res <- strsplit(res, "\\:")

  if (!identical(vapply(res, length, numeric(1)), c(2, 2, 2))) {
    abort("Failed to parse output from odbcinst.", .internal = TRUE)
  }

  res <- vapply(res, `[[`, character(1), 2)
  res <- trimws(res)
  names(res) <- c("drivers", "system_dsn", "user_dsn")

  res
}

system <- NULL

has_unixodbc <- function() {
  !identical(unname(Sys.which("odbcinst")), "")
}
