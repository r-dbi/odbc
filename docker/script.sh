#!/usr/bin/sh

/etc/init.d/postgresql start
sudo -u postgres psql -U postgres -c 'CREATE DATABASE test_db;'
sudo -u postgres psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'password';"
RDscript -e 'devtools::load_all();devtools::test()'
