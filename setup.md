## Test Setup

This file contains settings needed to setup local testing of odbc. It is most
useful for someone trying to develop the R package, so they can run the unit
tests locally.

## SQL Server test setup

### ini files

First we need to install the drivers and setup the ini files

`odbcinst.ini`
```ini
[SQL Server Driver]
Driver = /usr/local/lib/libtdsodbc.so
```

`odbc.ini`
```ini
[SQLServer]
driver = SQL Server Driver
Server = 127.0.0.1
port = 1433
```

Then we need to start an instance of SQL Server in a docker container.

```shell
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Passw0rd" \
   -p 1433:1433 --name sql1 \
   -d mcr.microsoft.com/mssql/server:2017-latest
```

Then do some configuration of the server to add a testuser and create the test database

```r
library(DBI); con <- dbConnect(odbc::odbc(), "SQLServer", UID = 'SA', PWD = 'Passw0rd');

# Add a test user
dbExecute(con, "EXEC sp_configure 'contained database authentication', 1")
dbExecute(con, "RECONFIGURE")
dbExecute(con, "alter database test set containment = partial")
dbExecute(con, "CREATE USER testuser with password = 'passW0rd!'")

# Create a test database
dbExecute(con, "CREATE DATABASE test")
```
