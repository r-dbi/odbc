#!/usr/bin/env bash
set -euo pipefail

# See #796 for some reasoning behind not using the canned mariadb-odbc-driver (v3.1.15), at time of writing
# and needing to install v3.1.17 from source
sudo apt-get install -y cmake
cd /tmp && git clone https://github.com/MariaDB/mariadb-connector-odbc.git connector
cd connector && git checkout 3.1.17
mkdir build && cd build
# 3.1.17 declares cmake_minimum_required() < 3.5, which CMake >= 4 (ubuntu-26.04) rejects
# unless CMAKE_POLICY_VERSION_MINIMUM is set.
cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCONC_WITH_UNIT_TESTS=Off -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_SSL=OPENSSL -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build . --config RelWithDebInfo
sudo make install
sudo ln -s /usr/local/lib/mariadb/libmariadb.so.3 /usr/local/lib/
sudo ldconfig
