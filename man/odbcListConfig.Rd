% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/odbc-config.R
\name{odbcListConfig}
\alias{odbcListConfig}
\alias{odbcEditDrivers}
\alias{odbcEditSystemDSN}
\alias{odbcEditUserDSN}
\title{List locations of ODBC configuration files}
\usage{
odbcListConfig()

odbcEditDrivers()

odbcEditSystemDSN()

odbcEditUserDSN()
}
\description{
On MacOS and Linux, odbc uses the unixODBC driver manager to manage
information about driver and data sources. This helper returns the filepaths
where the driver manager will look for that information.

\code{odbcListConfig()} is a wrapper around the command line call \code{odbcinst -j}.
The \code{\link[=odbcEditDrivers]{odbcEditDrivers()}}, \code{\link[=odbcEditSystemDSN]{odbcEditSystemDSN()}}, and
\code{\link[=odbcEditUserDSN]{odbcEditUserDSN()}} helpers provide a shorthand for
\code{file.edit(odbcListConfig()[[i]])}.

Windows does not use \code{.ini} configuration files; on Windows,
\code{odbcListConfig()} will return a 0-length vector and \verb{odbcEdit*()}
will raise an error.
}
\examples{
\dontshow{if (FALSE) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
configs <- odbcListConfig()

configs

# shorthand for file.edit(configs[[1]])
odbcEditDrivers()
\dontshow{\}) # examplesIf}
}
\seealso{
The \code{\link[=odbcListDrivers]{odbcListDrivers()}} and \code{\link[=odbcListDataSources]{odbcListDataSources()}} helpers return
information on the contents of \code{odbcinst.ini} and \code{odbc.ini} files,
respectively. \code{\link[=odbcListDataSources]{odbcListDataSources()}} collates entries from both the
System and User \code{odbc.ini} files.

Learn more about unixODBC and the \code{odbcinst} utility
\href{https://www.unixodbc.org/odbcinst.html}{here}.
}
