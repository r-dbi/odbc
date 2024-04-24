sudo apt-get install -y cmake
cd /tmp && git clone https://github.com/MariaDB/mariadb-connector-odbc.git connector
cd connector && git checkout 3.1.17
mkdir build && cd build
cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCONC_WITH_UNIT_TESTS=Off -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_SSL=OPENSSL
cmake --build . --config RelWithDebInfo
sudo make install
sudo ln -s /usr/local/lib/mariadb/libmariadb.so.3 /usr/local/lib/
sudo ldconfig
