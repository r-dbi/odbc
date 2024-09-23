#' List locations of ODBC configuration files
#'
#' @description
#' On MacOS and Linux, odbc uses the unixODBC driver manager to manage
#' information about driver and data sources. This helper returns the filepaths
#' where the driver manager will look for that information.
#'
#' `odbcListConfig()` is a wrapper around the command line call `odbcinst -j`.
#' The [odbcEditDrivers()], [odbcEditSystemDSN()], and
#' [odbcEditUserDSN()] helpers provide a shorthand for
#' `file.edit(odbcListConfig()[[i]])`.
#'
#' Windows does not use `.ini` configuration files; on Windows,
#' `odbcListConfig()` will return a 0-length vector and `odbcEdit*()`
#' will raise an error.
#'
#' @seealso
#' The [odbcListDrivers()] and [odbcListDataSources()] helpers return
#' information on the contents of `odbcinst.ini` and `odbc.ini` files,
#' respectively. [odbcListDataSources()] collates entries from both the
#' System and User `odbc.ini` files.
#'
#' Learn more about unixODBC and the `odbcinst` utility
#' [here](https://www.unixodbc.org/odbcinst.html).
#'
#' @examplesIf FALSE
#' configs <- odbcListConfig()
#'
#' configs
#'
#' # shorthand for file.edit(configs[[1]])
#' odbcEditDrivers()
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

#' @rdname odbcListConfig
#' @export
odbcEditDrivers <- function() {
  open_config(1)
}

#' @rdname odbcListConfig
#' @export
odbcEditSystemDSN <- function() {
  open_config(2)
}

#' @rdname odbcListConfig
#' @export
odbcEditUserDSN <- function() {
  open_config(3)
}

open_config <- function(idx, call = caller_env()) {
  config <- odbcListConfig()

  if (length(config) == 0) {
    cli::cli_abort(
      c(
        "Configuration files are only available on macOS and Linux.",
        "i" = "Use the ODBC Data Source Administrator to configure connections on Windows."
      ),
      call = call
    )
  }

  utils::file.edit(config[[idx]])
}

system <- NULL

has_unixodbc <- function() {
  !identical(unname(Sys.which("odbcinst")), "")
}
