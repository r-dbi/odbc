#!/usr/bin/env bash
set -euo pipefail

# See #796 for some reasoning behind not using the canned mariadb-odbc-driver (v3.1.15), at time of writing
# and needing to install >= v3.1.17 from source.
# 3.2.10: older tags don't build on ubuntu-26.04 (CMake 4 rejects cmake_minimum_required() < 3.5,
# and GCC 15 defaults to C23, where libmariadb's `typedef char bool` is an error).
sudo apt-get install -y cmake
cd /tmp && git clone https://github.com/MariaDB/mariadb-connector-odbc.git connector
cd connector && git checkout 3.2.10
mkdir build && cd build
cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCONC_WITH_UNIT_TESTS=Off -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_SSL=OPENSSL
cmake --build . --config RelWithDebInfo
sudo make install
sudo ln -s /usr/local/lib/mariadb/libmariadb.so.3 /usr/local/lib/
sudo ldconfig
