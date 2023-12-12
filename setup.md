## Test Setup

While the odbc package contains some documentation on how to install and configure database drivers in `vignette("setup")`, the documentation assumes that users are connecting to databases that have already been set up. In order to test package functionality, though, odbc sets up small example database deployments. This file documents how to set up the needed dependencies to host these databases locally and is intended for developers of the R package.

## PostgreSQL and MySQL

Run them locally with `brew services start mysql` `brew services start postgres`
Create a 'test' database and a 'postgres' user with 'password' as the password.

See the configuration files in .github/odbc for examples.

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
library(DBI); con <- dbConnect(odbc::odbc(), "SQLServer", UID = 'SA', PWD = 'Password12')

# Add a test user, but currently unused
dbExecute(con, "USE test")
dbExecute(con, "EXEC sp_configure 'contained database authentication', 1")
dbExecute(con, "RECONFIGURE")
dbExecute(con, "alter database test set containment = partial")
dbExecute(con, "CREATE USER testuser with password = 'Password12'")
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

# Oracle

A huge pain.

## Get the DB container

```shell
docker login

docker pull store/oracle/database-enterprise:12.2.0.1
```

## Start the container

The -P is important to setup the port forwarding from the docker container

```shell
docker run -d -it --name oracle_db -P store/oracle/database-enterprise:12.2.0.1
```

## Query the port and edit the ports in tnsnames.ora

```shell
docker port oracle_db
```

Contents of `snsnames.ora`

```
ORCLCDB=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=32769))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=ORCLCDB.localdomain)))
ORCLPDB1=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=32769))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=ORCLPDB1.localdomain)))
```

Set the current working directory as the 

## Add a new user to the DB

docker exec -it oracle_db bash -c "source /home/oracle/.bashrc; sqlplus SYS/Oradoc_db1 AS SYSDBA"

```sql
alter session set "_ORACLE_SCRIPT"=true;

create user test identified by 12345;

GRANT ALL PRIVILEGES TO TEST;
```

```r
Sys.setenv("TNS_ADMIN" = getwd())
con <- dbConnect(odbc::odbc(), "OracleODBC-19")
```
