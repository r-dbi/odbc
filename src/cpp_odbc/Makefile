CXX_FLAGS = -Wall -Wextra -Wno-unused-parameter -g -O0 -pedantic -fPIC -std=c++03
LDFLAGS=-liodbc

LIBRARY_SOURCES=src/column_description.cpp src/connection.cpp src/cpp_odbc.cpp src/environment.cpp src/error.cpp src/statement.cpp src/level1/api.cpp src/level1/level1.cpp src/level1/unixodbc_backend.cpp src/level1/unixodbc_backend_debug.cpp src/level2/api.cpp src/level2/handles.cpp src/level2/input_string_buffer.cpp src/level2/level1_connector.cpp src/level2/level2.cpp src/level2/string_buffer.cpp src/level3/level3.cpp src/level3/raii_connection.cpp src/level3/raii_environment.cpp src/level3/raii_statement.cpp src/make_environment.cpp src/multi_value_buffer.cpp
LIBRARY_OBJECTS=$(LIBRARY_SOURCES:.cpp=.o)
LIBRARY=libcpp_odbc.a

all: $(LIBRARY) $(LIBRARY_SOURCES)

$(LIBRARY): $(LIBRARY_OBJECTS)
	$(AR) -rc $@ $?

.cpp.o:
	$(CXX) -c $(CXX_FLAGS) -o $@ $< -I.

clean:
	rm -f **/*o $(LIBRARY)
