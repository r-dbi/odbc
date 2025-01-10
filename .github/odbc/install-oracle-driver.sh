sudo apt-get install -y libaio-dev
sudo ln -s /lib/x86_64-linux-gnu/libaio.so /lib/x86_64-linux-gnu/libaio.so.1
mkdir -p /opt/oracle 
wget --quiet -O /opt/oracle/instantclient-basic-linux.x64-21.12.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-basic-linux.x64-21.12.0.0.0dbru.zip
wget --quiet -O /opt/oracle/instantclient-odbc-linux.x64-21.12.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-odbc-linux.x64-21.12.0.0.0dbru.zip
cd /opt/oracle/
unzip instantclient-basic-linux.x64-21.12.0.0.0dbru.zip
unzip instantclient-odbc-linux.x64-21.12.0.0.0dbru.zip
