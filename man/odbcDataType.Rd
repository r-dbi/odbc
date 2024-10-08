% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aaa-odbc-data-type.R, R/driver-access.R,
%   R/driver-bigquery.R, R/driver-hive.R, R/driver-impala.R, R/driver-mysql.R,
%   R/driver-netezza.R, R/driver-oracle.R, R/driver-postgres.R,
%   R/driver-redshift.R, R/driver-snowflake.R, R/driver-spark.R,
%   R/driver-sql-server.R, R/driver-sqlite.R, R/driver-teradata.R,
%   R/driver-vertica.R
\name{odbcDataType}
\alias{odbcDataType}
\alias{odbcDataType,ANY-method}
\alias{odbcDataType,ACCESS-method}
\alias{odbcDataType,BigQuery-method}
\alias{odbcDataType,Hive-method}
\alias{odbcDataType,Impala-method}
\alias{odbcDataType,MySQL-method}
\alias{odbcDataType,NetezzaSQL-method}
\alias{odbcDataType,Oracle-method}
\alias{odbcDataType,PostgreSQL-method}
\alias{odbcDataType,Redshift-method}
\alias{odbcDataType,Snowflake-method}
\alias{odbcDataType,Spark SQL-method}
\alias{odbcDataType,Microsoft SQL Server-method}
\alias{odbcDataType,SQLite-method}
\alias{odbcDataType,Teradata-method}
\alias{odbcDataType,Vertica Database-method}
\title{Return the corresponding ODBC data type for an R object}
\usage{
odbcDataType(con, obj, ...)
}
\arguments{
\item{con}{A driver connection object, as returned by \code{dbConnect()}.}

\item{obj}{An R object.}

\item{...}{Additional arguments passed to methods.}
}
\value{
Corresponding SQL type for the \code{obj}.
}
\description{
This is used when creating a new table with \code{dbWriteTable()}.
Databases with default methods defined are:
\itemize{
\item MySQL
\item PostgreSQL
\item SQL Server
\item Oracle
\item SQLite
\item Spark
\item Hive
\item Impala
\item Redshift
\item Vertica
\item BigQuery
\item Teradata
\item Access
\item Snowflake
}
}
\details{
If you are using a different database and \code{dbWriteTable()} fails with a SQL
parsing error the default method is not appropriate, you will need to write
a new method. The object type for your method will be the database name
retrieved by \code{dbGetInfo(con)$dbms.name}. Use the documentation provided with
your database to determine appropriate values for each R data type.
}
