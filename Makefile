# Required environment variables:
# ODBC_CONFIG - Depending on your ODBC library, name of your odbc config binary (iodobc-config for iODBC and odbc_config for unixODBC, for example)
# ODBC_FLAGS - Compile/linker flags needed for whatever ODBC driver you are using ("-I/opt/vertica/include -lverticaodbc -L/opt/vertica/lib64" for Vertica's driver, for example)

all:
	# Example build for clang++
	clang++ example.cpp nanodbc.cpp -o example $(${ODBC_CONFIG} --libs) ${ODBC_FLAGS} -Wall -g -std=c++03

unicode:
	# Example unicode build for clang++
	clang++ example.cpp nanodbc.cpp -o example $(${ODBC_CONFIG} --libs) ${ODBC_FLAGS} -Wall -g -std=c++03 -DNANODBC_USE_UNICODE

cpp11:
	# Example build for clang++ with C++11
	clang++ example.cpp nanodbc.cpp -o example $(${ODBC_CONFIG} --libs) ${ODBC_FLAGS} -Wall -g -std=c++11 -DNANODBC_USE_CPP11

gnu:
	# Example build for g++
	g++ example.cpp nanodbc.cpp -o example $(${ODBC_CONFIG} --libs) ${ODBC_FLAGS} -Wall -g --std=c++03

gnu11:
	# Example build for g++
	g++ example.cpp nanodbc.cpp -o example $(${ODBC_CONFIG} --libs) ${ODBC_FLAGS} -Wall -g --std=c++11 -DNANODBC_USE_CPP11

clean:
	rm -rf example example.dSYM
