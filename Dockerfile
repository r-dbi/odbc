# FROM ubuntu:latest
# RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
#     DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common

# travis-ci unit tests run using ubuntu:precise, but development is often
# far less painful using ubuntu:latest instead. In future we can drop precise.
FROM ubuntu:precise
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install python-software-properties

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        $(apt-cache -q search "libboost-locale1\..*-dev" | awk '{print $1}') \
        cmake \
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

RUN odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
RUN odbcinst -i -d -f /usr/share/sqliteodbc/unixodbc.ini

ENV CXX g++-5
