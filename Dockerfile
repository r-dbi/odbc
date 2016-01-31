# FROM ubuntu:latest
# RUN DEBIAN_FRONTEND=noninteractive apt-get -qqy update
#  && DEBIAN_FRONTEND=noninteractive apt-get -qqy install software-properties-common

# travis-ci unit tests run using ubuntu:precise, but development is often
# far less painful using ubuntu:latest instead. In future we can drop precise.
FROM ubuntu:precise
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qqy \
 && DEBIAN_FRONTEND=noninteractive apt-get -qqy install python-software-properties

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qqy \
 && DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
        $(apt-cache -q search "libboost-locale1\..*-dev" | awk '{print $1}') \
        cmake \
        doxygen \
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

# Might not be available, but install it if it is.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install jekyll || true

# Cleanup so image is smaller
RUN DEBIAN_FRONTEND=noninteractive apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
RUN odbcinst -i -d -f /usr/share/sqliteodbc/unixodbc.ini

ENV CXX g++-5
