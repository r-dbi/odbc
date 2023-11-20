% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db.R
\docType{class}
\name{Microsoft SQL Server-class}
\alias{Microsoft SQL Server-class}
\alias{dbUnquoteIdentifier,Microsoft SQL Server,SQL-method}
\alias{isTempTable,Microsoft SQL Server,character-method}
\alias{dbExistsTable,Microsoft SQL Server,character-method}
\alias{dbExistsTable}
\alias{sqlCreateTable,Microsoft SQL Server-method}
\title{Simple class prototype to avoid messages about unknown classes from setMethod}
\arguments{
\item{conn}{A \linkS4class{DBIConnection} object, as returned by
\code{\link[DBI:dbConnect]{dbConnect()}}.}

\item{x}{An \link[DBI]{SQL} or \link[DBI]{Id} object.}

\item{...}{Other arguments passed on to methods.}

\item{name}{The table name, passed on to \code{\link[DBI:dbQuoteIdentifier]{dbQuoteIdentifier()}}. Options are:
\itemize{
\item a character string with the unquoted DBMS table name,
e.g. \code{"table_name"},
\item a call to \code{\link[DBI:Id]{Id()}} with components to the fully qualified table name,
e.g. \code{Id(schema = "my_schema", table = "table_name")}
\item a call to \code{\link[DBI:SQL]{SQL()}} with the quoted and fully qualified table name
given verbatim, e.g. \code{SQL('"my_schema"."table_name"')}
}}

\item{con}{A database connection.}

\item{table}{The table name, passed on to \code{\link[DBI:dbQuoteIdentifier]{dbQuoteIdentifier()}}. Options are:
\itemize{
\item a character string with the unquoted DBMS table name,
e.g. \code{"table_name"},
\item a call to \code{\link[DBI:Id]{Id()}} with components to the fully qualified table name,
e.g. \code{Id(schema = "my_schema", table = "table_name")}
\item a call to \code{\link[DBI:SQL]{SQL()}} with the quoted and fully qualified table name
given verbatim, e.g. \code{SQL('"my_schema"."table_name"')}
}}

\item{fields}{Either a character vector or a data frame.

A named character vector: Names are column names, values are types.
Names are escaped with \code{\link[DBI:dbQuoteIdentifier]{dbQuoteIdentifier()}}.
Field types are unescaped.

A data frame: field types are generated using
\code{\link[DBI:dbDataType]{dbDataType()}}.}

\item{row.names}{Either \code{TRUE}, \code{FALSE}, \code{NA} or a string.

If \code{TRUE}, always translate row names to a column called "row_names".
If \code{FALSE}, never translate row names. If \code{NA}, translate
rownames only if they're a character vector.

A string is equivalent to \code{TRUE}, but allows you to override the
default name.

For backward compatibility, \code{NULL} is equivalent to \code{FALSE}.}

\item{temporary}{If \code{TRUE}, will generate a temporary table statement.}
}
\value{
\code{dbExistsTable()} returns a logical scalar, \code{TRUE} if the table or view
specified by the \code{name} argument exists, \code{FALSE} otherwise.

This includes temporary tables if supported by the database.
}
\description{
For SQL Server, \code{conn@quote} will return the quotation mark, however
both quotation marks as well as square bracket are used interchangeably for
delimited identifiers.  See:
\url{https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers?view=sql-server-ver16}
Therefore strip the brackets first, and then call the DBI method that strips
the quotation marks.
TODO: the generic implementation in DBI should take a quote char as
parameter.

Local temp tables are stored as
\code{ [tempdb].[dbo].[#name]________(padding using underscores)[numeric identifier] }

If we can identify that the name is that of a local temp table
then adjust the identifier and query appropriately.

Will warn user if \code{temporary} is set to TRUE but table name does not conform
to local temp table naming conventions.  If writing to a global temp table, user
should not set the temporary flag to TRUE.
}
\details{
True if:
\itemize{
\item If catalog_name is supplied it must equal "temdb" or "\%" ( wildcard )
\item Name must start with "#" followd by a non-"#" character
}

Note, the implementation here is such that it assumes the metadata attribute is
set such that catalog functions accept wildcard entries.

Driver note.  OEM driver will return correctly for
name, \code{catalog_name = "tempdb"} in some circumstances.  For exmaple
if the name has no underscores to beginwith.  FreeTDS, will not index
the table correctly unless name is adjusted ( allowed trailing wildcards to
accomodate trailing underscores and postfix ).

Therefore, in all cases query for \code{name___\%}.

In both cases a simple CREATE TABLE statement is used / the table identifier
is the differentiator ( viz-a-viz creating a non-temp table ).
}
\section{Failure modes}{



An error is raised when calling this method for a closed
or invalid connection.
An error is also raised
if \code{name} cannot be processed with \code{\link[DBI:dbQuoteIdentifier]{dbQuoteIdentifier()}}
or if this results in a non-scalar.


}

\section{Specification}{



The \code{name} argument is processed as follows,
to support databases that allow non-syntactic names for their objects:
\itemize{
\item If an unquoted table name as string: \code{dbExistsTable()} will do the
quoting,
perhaps by calling \code{dbQuoteIdentifier(conn, x = name)}
\item If the result of a call to \code{\link[DBI:dbQuoteIdentifier]{dbQuoteIdentifier()}}: no more quoting is done
}

For all tables listed by \code{\link[DBI:dbListTables]{dbListTables()}}, \code{dbExistsTable()} returns \code{TRUE}.


}

\examples{
con <- dbConnect(RSQLite::SQLite(), ":memory:")

dbExistsTable(con, "iris")
dbWriteTable(con, "iris", iris)
dbExistsTable(con, "iris")

dbDisconnect(con)
}
\seealso{
Other DBIConnection generics: 
\code{\link[DBI]{DBIConnection-class}},
\code{\link[DBI]{dbAppendTable}()},
\code{\link[DBI]{dbCreateTable}()},
\code{\link[DBI]{dbDataType}()},
\code{\link[DBI]{dbDisconnect}()},
\code{\link[DBI]{dbExecute}()},
\code{\link[DBI]{dbGetException}()},
\code{\link[DBI]{dbGetInfo}()},
\code{\link[DBI]{dbGetQuery}()},
\code{\link[DBI]{dbIsReadOnly}()},
\code{\link[DBI]{dbIsValid}()},
\code{\link[DBI]{dbListFields}()},
\code{\link[DBI]{dbListObjects}()},
\code{\link[DBI]{dbListResults}()},
\code{\link[DBI]{dbListTables}()},
\code{\link[DBI]{dbReadTable}()},
\code{\link[DBI]{dbRemoveTable}()},
\code{\link[DBI]{dbSendQuery}()},
\code{\link[DBI]{dbSendStatement}()},
\code{\link[DBI]{dbWriteTable}()}
}