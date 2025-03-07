% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/driver-sql-server.R
\docType{class}
\name{Microsoft SQL Server-class}
\alias{Microsoft SQL Server-class}
\alias{dbUnquoteIdentifier,Microsoft SQL Server,SQL-method}
\alias{isTempTable,Microsoft SQL Server,character-method}
\alias{isTempTable,Microsoft SQL Server,SQL-method}
\alias{dbExistsTable,Microsoft SQL Server,character-method}
\alias{dbListTables,Microsoft SQL Server-method}
\alias{dbExistsTable,Microsoft SQL Server,Id-method}
\alias{dbExistsTable,Microsoft SQL Server,SQL-method}
\alias{odbcConnectionSchemas,Microsoft SQL Server-method}
\alias{sqlCreateTable,Microsoft SQL Server-method}
\alias{odbcConnectionColumns_,Microsoft SQL Server,character-method}
\alias{odbcConnectionColumns_,Microsoft SQL Server,SQL-method}
\title{SQL Server}
\description{
Details of SQL Server methods for odbc and DBI generics.

\subsection{\code{dbUnquoteIdentifier()}}{

\code{conn@quote} returns the quotation mark, but quotation marks and square
brackets can be used interchangeably for delimited identifiers.
(\url{https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers}).
This function strips the brackets first and then calls the DBI method to
strip the quotation marks.
}

\subsection{\code{isTempTable()}}{

Local temp tables are stored as
\verb{[tempdb].[dbo].[#name]_____[numeric identifier]}, so \code{isTempTable()}
returns \code{TRUE} if \code{catalog_name} is \code{"tempdb"} or \code{"\%"}, or the
name starts with \code{"#"}.
}

\subsection{\code{dbExistsTable()}}{

The default implementation reports temporary tables as non-existent
since they live in a different catalog. This method provides a special
case for temporary tables, as identified by \code{isTempTable()}.
}

\subsection{\code{dbListTables()}}{

The default implementation reports temporary tables as non-existent
when a \code{catalog_name} isn't supplied since they live in a different catalog.
This method provides a special case for temporary tables.
}

\subsection{\code{odbcConnectionSchemas}}{

Method for an internal function. Calls catalog-specific \code{sp_tables} to make
sure we list the schemas in the appropriate database/catalog.
}

\subsection{\code{sqlCreateTable()}}{

Warns if \code{temporary = TRUE} but the \code{name} does not conform to temp table
naming conventions (i.e. it doesn't start with \verb{#}).
}

\subsection{\code{odbcConnectionColumns_()}}{

If temp table, query the database for the
actual table name.
}

\subsection{\code{odbcConnectionColumns_()}}{

Copied over from odbc-connection to avoid S4 dispatch NOTEs.
}
}
\keyword{internal}
