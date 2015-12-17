FROM ubuntu:latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        cmake \
        g++-5 \
        git \
        libboost-locale1.55-dev \
        libboost-test1.55-dev \
        libmyodbc \
        libsqliteodbc \
        mysql-client \
        mysql-server \
        unixodbc \
        unixodbc-dev

RUN odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
RUN odbcinst -i -d -f /usr/share/sqliteodbc/unixodbc.ini

ENV CXX g++-5
