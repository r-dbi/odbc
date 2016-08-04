CXX_FLAGS = -Wall -g -O0 -pedantic -fPIC -std=c++11 -I../cpp_odbc -I/usr/local/lib/R/3.2/site-library/Rcpp/include/
LDFLAGS=-L../cpp_odbc -liodbc -lcpp_odbc

LIBRARY_SOURCES= src/column.cpp src/field_translators/float64_translator.cpp src/connect.cpp src/field_translators/int64_translator.cpp src/connection.cpp src/field_translators/string_translator.cpp src/cursor.cpp src/field_translators/timestamp_translator.cpp src/description.cpp src/make_description.cpp src/descriptions/boolean_description.cpp src/make_field_translator.cpp src/descriptions/date_description.cpp src/parameter.cpp src/descriptions/floating_point_description.cpp src/query.cpp src/descriptions/integer_description.cpp src/result_sets/bound_result_set.cpp src/descriptions/string_description.cpp src/result_sets/double_buffered_result_set.cpp src/descriptions/timestamp_description.cpp src/result_sets/field_result_set.cpp src/field_translator.cpp src/field_translators/boolean_translator.cpp src/result_sets/result_set.cpp src/field_translators/date_translator.cpp src/result_sets/row_based_result_set.cpp src/result_sets/r_result_set.cpp
LIBRARY_OBJECTS=$(LIBRARY_SOURCES:.cpp=.o)
LIBRARY=libturbodbc.a

all: $(LIBRARY) $(LIBRARY_SOURCES)

$(LIBRARY): $(LIBRARY_OBJECTS)
	$(AR) -rc $@ $?

.cpp.o:
	$(CXX) -c $(CXX_FLAGS) -o $@ $< -I.

clean:
	rm -f **/*o $(LIBRARY)
