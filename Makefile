all:
	# Example build for clang++ using iODBC on OS X
	clang++ example.cpp nanodbc.cpp -o example $(iodbc-config --libs) ${ODBC_FLAGS} -Wall -g

cpp11:
	# Example build for clang++ with C++11 using iODBC on OS X
	clang++ example.cpp nanodbc.cpp -o example $(iodbc-config --libs) ${ODBC_FLAGS} -Wall -g -std=c++11 -stdlib=libc++ -DNANODBC_USE_CPP11

gnu:
	# Example build for g++ using iODBC on OS X
	g++ example.cpp nanodbc.cpp -o example $(iodbc-config --libs) ${ODBC_FLAGS} -Wall -g

clean:
	rm -rf example example.dSYM