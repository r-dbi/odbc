# Package index

## DBI methods

- [`odbc()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  [`dbConnect(`*`<OdbcDriver>`*`)`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  : Connect to a database via an ODBC driver
- [`dbListTables(`*`<OdbcConnection>`*`)`](https://odbc.r-dbi.org/dev/reference/dbListTables-OdbcConnection-method.md)
  : List remote tables and fields for an ODBC connection
- [`dbWriteTable(`*`<OdbcConnection>`*`,`*`<character>`*`,`*`<data.frame>`*`)`](https://odbc.r-dbi.org/dev/reference/DBI-tables.md)
  [`dbWriteTable(`*`<OdbcConnection>`*`,`*`<Id>`*`,`*`<data.frame>`*`)`](https://odbc.r-dbi.org/dev/reference/DBI-tables.md)
  [`dbWriteTable(`*`<OdbcConnection>`*`,`*`<SQL>`*`,`*`<data.frame>`*`)`](https://odbc.r-dbi.org/dev/reference/DBI-tables.md)
  [`dbAppendTable(`*`<OdbcConnection>`*`)`](https://odbc.r-dbi.org/dev/reference/DBI-tables.md)
  [`sqlCreateTable(`*`<OdbcConnection>`*`)`](https://odbc.r-dbi.org/dev/reference/DBI-tables.md)
  : Convenience functions for reading/writing DBMS tables

## Database-specific helpers

- [`databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  [`dbConnect(`*`<DatabricksOdbcDriver>`*`)`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  : Helper for Connecting to Databricks via ODBC
- [`Microsoft SQL Server-class`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`dbUnquoteIdentifier,Microsoft SQL Server,SQL-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`isTempTable,Microsoft SQL Server,character-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`isTempTable,Microsoft SQL Server,SQL-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`dbExistsTable,Microsoft SQL Server,character-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`dbListTables,Microsoft SQL Server-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`dbExistsTable,Microsoft SQL Server,Id-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`dbExistsTable,Microsoft SQL Server,SQL-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`odbcConnectionSchemas,Microsoft SQL Server-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`sqlCreateTable,Microsoft SQL Server-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`odbcConnectionColumns_,Microsoft SQL Server,character-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  [`odbcConnectionColumns_,Microsoft SQL Server,SQL-method`](https://odbc.r-dbi.org/dev/reference/SQLServer.md)
  : SQL Server
- [`sqlCreateTable(`*`<Oracle>`*`)`](https://odbc.r-dbi.org/dev/reference/Oracle.md)
  [`odbcConnectionTables(`*`<Oracle>`*`,`*`<character>`*`)`](https://odbc.r-dbi.org/dev/reference/Oracle.md)
  : Oracle
- [`redshift()`](https://odbc.r-dbi.org/dev/reference/redshift.md)
  [`dbConnect(`*`<RedshiftOdbcDriver>`*`)`](https://odbc.r-dbi.org/dev/reference/redshift.md)
  : Helper for Connecting to Redshift via ODBC
- [`snowflake()`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  [`dbConnect(`*`<SnowflakeOdbcDriver>`*`)`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  : Helper for connecting to Snowflake via ODBC

## ODBC configuration

- [`odbc()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  [`dbConnect(`*`<OdbcDriver>`*`)`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  : Connect to a database via an ODBC driver
- [`dbExistsTableForWrite(`*`<Snowflake>`*`,`*`<character>`*`)`](https://odbc.r-dbi.org/dev/reference/driver-Snowflake.md)
  : Connecting to Snowflake via ODBC
- [`odbcDataType()`](https://odbc.r-dbi.org/dev/reference/odbcDataType.md)
  : Return the corresponding ODBC data type for an R object
- [`odbcListColumns()`](https://odbc.r-dbi.org/dev/reference/odbcListColumns.md)
  : List columns in an object.
- [`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  [`odbcEditDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  [`odbcEditSystemDSN()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  [`odbcEditUserDSN()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  : List locations of ODBC configuration files
- [`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
  : List Configured Data Source Names
- [`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
  : List Configured ODBC Drivers
- [`odbcListObjectTypes()`](https://odbc.r-dbi.org/dev/reference/odbcListObjectTypes.md)
  : Return the object hierarchy supported by a connection.
- [`odbcListObjects()`](https://odbc.r-dbi.org/dev/reference/odbcListObjects.md)
  : List objects in a connection.
- [`odbcPreviewObject()`](https://odbc.r-dbi.org/dev/reference/odbcPreviewObject.md)
  : Preview the data in an object.
- [`odbcSetTransactionIsolationLevel()`](https://odbc.r-dbi.org/dev/reference/odbcSetTransactionIsolationLevel.md)
  : Set the Transaction Isolation Level for a Connection
- [`isTempTable()`](https://odbc.r-dbi.org/dev/reference/isTempTable.md)
  : Helper method used to determine if a table identifier is that of a
  temporary table.
- [`quote_value()`](https://odbc.r-dbi.org/dev/reference/quote_value.md)
  : Quote special character when connecting
