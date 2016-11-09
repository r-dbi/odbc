FROM rocker/r-devel-san

RUN apt-get -qq update \
	&& apt-get -qq dist-upgrade -y \
	&& apt-get -qq install git unixodbc unixodbc-dev postgresql-9.5 odbc-postgresql libssl-dev sudo -y

# Add postgres backends
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qqy \
 && DEBIAN_FRONTEND=noninteractive apt-get -qqy install gnupg software-properties-common

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qqy \
 && DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
        g++-5 \
        git \
        libmyodbc \
        libsqliteodbc \
        make \
        mysql-client \
        mysql-server \
        sqlite3 \
        unixodbc \
        unixodbc-dev \
        vim

RUN RD -e 'install.packages(c("devtools", "roxygen2", "testthat"), quiet = T)'
RUN RD -e 'devtools::install_github("hadley/odbc@nanodbc", dep = TRUE)'

ENV CXX g++-5
ENV ODBCSYSINI=/opt/odbc/travis/odbc
