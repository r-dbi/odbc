FROM ubuntu:latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        cmake \
        g++-5 \
        libboost-locale-dev \
        libboost-test-dev \
        libiodbc2 \
        libiodbc2-dev \
        libsqliteodbc

RUN echo "\n\
[sqlite]\n\
Description             = SQLite ODBC Driver\n\
Driver                  = $(dpkg-query -L libsqliteodbc | egrep -i 'libsqlite3odbc.so$')\n\
Setup                   = $(dpkg-query -L libsqliteodbc | egrep -i 'libsqlite3odbc.so$')\n\
Threading               = 2\n" > "$(iodbc-config --odbcinstini)"

ENV CXX g++-5
