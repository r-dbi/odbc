cmake_minimum_required(VERSION 2.6) 
project(nanodbc) 

add_library(nanodbc SHARED nanodbc.cpp)

find_program(ODBC_CONFIG odbc_config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)

if(NOT ODBC_CONFIG)
	find_program(ODBC_CONFIG iodbc-config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)
endif()

if(NOT ODBC_CONFIG)
	message(FATAL_ERROR "can not find odbc config program")
endif()

execute_process(COMMAND ${ODBC_CONFIG} --libs OUTPUT_VARIABLE ODBC_LINK_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND ${ODBC_CONFIG} --cflags OUTPUT_VARIABLE ODBC_COMPILE_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)

set_target_properties(nanodbc PROPERTIES COMPILE_FLAGS ${ODBC_COMPILE_FLAGS})
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ODBC_LINK_FLAGS}")

if(${NANODBC_USE_UNICODE})
	add_definitions(-DNANODBC_USE_UNICODE)
endif()

if(${NANODBC_USE_CPP11})
	add_definitions(-DNANODBC_USE_CPP11 --std=c++11)
else()
	add_definitions(--std=c++03)
endif()

add_executable(example example.cpp)
target_link_libraries(example nanodbc)

install(FILES nanodbc.h DESTINATION include)
install(TARGETS nanodbc LIBRARY DESTINATION lib)
