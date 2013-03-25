all:
	# Example build for clang++ using iODBC on OS X
	clang++ example.cpp nanodbc.cpp -o example $(iodbc-config --libs) -Wall -Wno-deprecated-declarations ${ODBC_FLAGS} -g

cpp11:
	# Example build for clang++ with C++11 using iODBC on OS X
	clang++ example.cpp nanodbc.cpp -o example $(iodbc-config --libs) -Wall -Wno-deprecated-declarations ${ODBC_FLAGS} -g -std=c++11 -stdlib=libc++ -DNANODBC_USE_CPP11

clean:
	rm -rf example.dSYM example example.html highlight.css

dox:
	make clean
	find doc/doxygen -type f -not -name header.html -and -not -name footer.html | xargs rm 
	doxygen
