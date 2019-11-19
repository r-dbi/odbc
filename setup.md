## Test Setup

This file contains settings needed to setup local testing of odbc. It is most
useful for someone trying to develop the R package, so they can run the unit
tests locally.

## SQL Server test setup

Install the [microsoft drivers](https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#macos)

```shell
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install msodbcsql17 mssql-tools
```

### ini files

First we need to install the drivers and setup the ini files

`odbc.ini`
```ini
[MicrosoftSQLServer]
driver = ODBC Driver 17 for SQL Server
Server = 127.0.0.1
port = 1433
```

Then we need to start an instance of SQL Server in a docker container.

```shell
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Password12" \
   -p 1433:1433 --name sql1 \
   -d mcr.microsoft.com/mssql/server:2017-latest
```

Then do some configuration of the server to add a testuser and create the test database

```r
library(DBI); con <- dbConnect(odbc::odbc(), "SQLServer", UID = 'SA', PWD = 'Passw0rd')

# Add a test user
dbExecute(con, "USE test")
dbExecute(con, "EXEC sp_configure 'contained database authentication', 1")
dbExecute(con, "RECONFIGURE")
dbExecute(con, "alter database test set containment = partial")
dbExecute(con, "CREATE USER testuser with password = 'passW0rd!'")
dbExecute(con, "GRANT CONTROL TO testuser")
dbExecute(con, "DROP USER testuser")

# Create a test database
dbExecute(con, "CREATE DATABASE test")
```

### RODBC

We need to install RODBC for benchmarking in the README. The CRAN version of RODBC uses
iODBC, so to use unixODBC we need to recompile it from source, specifying the
odbc manager explicitly.

```r

install.packages("RODBC", type = "source", INSTALL_opts="--configure-args='--with-odbc-manager=odbc'")
```

## Linux

Create docker container

```shell
docker run -v "$(pwd)":"/opt/$(basename $(pwd))":delegated --security-opt=seccomp:unconfined --link sql1 -it rstudio/r-base:3.6.1-bionic /bin/bash
```

In docker
```shell
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#Ubuntu 18.04
curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql17
apt-get install -y unixodbc-dev
```

```ini
[MicrosoftSQLServer]
driver = ODBC Driver 17 for SQL Server
Server = sql1
port = 1433
Database = test
```
