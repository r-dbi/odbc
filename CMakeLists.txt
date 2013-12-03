cmake_minimum_required(VERSION 2.6) 
project(nanodbc) 

########################################
## find unixODBC or iODBC config binary
########################################
find_program(ODBC_CONFIG odbc_config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)

if(NOT ODBC_CONFIG)
	find_program(ODBC_CONFIG iodbc-config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)
endif()

if(NOT ODBC_CONFIG)
	message(FATAL_ERROR "can not find odbc config program")
endif()

if(${NANODBC_USE_CPP11})
	add_definitions(-DNANODBC_USE_CPP11 --std=c++11)
else()
	add_definitions(--std=c++03)
endif()

########################################
## get ODBC compile and link flags
########################################
execute_process(COMMAND ${ODBC_CONFIG} --libs OUTPUT_VARIABLE ODBC_LINK_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND ${ODBC_CONFIG} --cflags OUTPUT_VARIABLE ODBC_COMPILE_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)

########################################
## optional NANODBC_USE_UNICODE
########################################
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ODBC_LINK_FLAGS}")
if(${NANODBC_USE_UNICODE})
	set(ODBC_COMPILE_FLAGS "${ODBC_COMPILE_FLAGS} -DNANODBC_USE_UNICODE")
endif()

########################################
## shared library
########################################
add_library(nanodbc SHARED nanodbc.cpp)
set_target_properties(nanodbc PROPERTIES COMPILE_FLAGS "${ODBC_COMPILE_FLAGS}")

install(FILES nanodbc.h DESTINATION include)
install(TARGETS nanodbc LIBRARY DESTINATION lib)

########################################
## executable example
########################################
add_executable(example EXCLUDE_FROM_ALL example.cpp)
target_link_libraries(example nanodbc)
