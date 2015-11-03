cmake_minimum_required(VERSION 2.6)
project(nanodbc)

option(NANODBC_USE_UNICODE "build with unicode support enabled" OFF)
option(NANODBC_USE_BOOST_CONVERT "build using Boost.Locale for string convert" OFF)
option(NANODBC_HANDLE_NODATA_BUG "enable special handling for SQL_NO_DATA (required for vertica)" OFF)
option(NANODBC_TEST "build tests" ON)
option(NANODBC_INSTALL "generate install target" ON)

if(APPLE)
	set(CMAKE_MACOSX_RPATH ON)
endif()

########################################
## require and enable C++0x/11/14
########################################
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_COMPILER_IS_GNUCXX)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")
	include(CheckCXXCompilerFlag)
	CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
	CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
	CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
	if(COMPILER_SUPPORTS_CXX14)
	    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
	elseif(COMPILER_SUPPORTS_CXX11)
	    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
	elseif(COMPILER_SUPPORTS_CXX0X)
	    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
	else()
	    message(WARNING "Compiler ${CMAKE_CXX_COMPILER} has no C++ 0x/11/14 support.")
	endif()
elseif(MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /WX")
	if (NOT (MSVC_VERSION LESS 1700))
		set(COMPILER_SUPPORTS_CXX0X TRUE)
	elseif (NOT (MSVC_VERSION LESS 1900))
		set(COMPILER_SUPPORTS_CXX11 TRUE)
	endif()
endif()

########################################
## find unixODBC or iODBC config binary
########################################
if (UNIX)
	find_program(ODBC_CONFIG odbc_config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)

	if(NOT ODBC_CONFIG)
		find_program(ODBC_CONFIG iodbc-config $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin PATHS)
	endif()

	if(NOT ODBC_CONFIG)
		message(FATAL_ERROR "can not find odbc config program")
	endif()
elseif(MSVC)
	set(ODBC_LIBRARIES odbc32.lib odbccp32.lib Ws2_32.lib)
endif()

########################################
## build options
########################################
if(NANODBC_ODBC_VERSION)
	message(STATUS "ODBC Version Override: ${NANODBC_ODBC_VERSION}")
endif()

if(NANODBC_USE_UNICODE)
	message(STATUS "Unicode support: Enabled")
	add_definitions(-DNANODBC_USE_UNICODE)
else()
	message(STATUS "Unicode support: Disabled")
endif()

if(NANODBC_USE_BOOST_CONVERT)
	message(STATUS "Boost string convert: Enabled")
	add_definitions(-DNANODBC_USE_BOOST_CONVERT)
else()
	message(STATUS "Boost string convert: Disabled")
endif()

if(NANODBC_HANDLE_NODATA_BUG)
	message(STATUS "Handle SQL_NO_DATA bug: Enabled")
	add_definitions(-DNANODBC_HANDLE_NODATA_BUG)
else()
	message(STATUS "Handle SQL_NO_DATA bug: Disabled")
endif()

########################################
## find Boost if necessary
########################################
if(NANODBC_USE_BOOST_CONVERT)
	set(Boost_USE_STATIC_LIBS ON)
	set(Boost_USE_MULTITHREADED ON)
	find_package(Boost COMPONENTS unit_test_framework REQUIRED)
endif()

########################################
## get ODBC compile and link flags
########################################
if (UNIX)
	execute_process(COMMAND ${ODBC_CONFIG} --libs OUTPUT_VARIABLE ODBC_LINK_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
	execute_process(COMMAND ${ODBC_CONFIG} --cflags OUTPUT_VARIABLE ODBC_COMPILE_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
	set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ODBC_LINK_FLAGS}")
endif()

########################################
## shared library
########################################
if(Boost_FOUND)
	include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/src ${Boost_INCLUDE_DIRS})
	link_directories(${CMAKE_BINARY_DIR}/lib ${Boost_LIBRARY_DIRS})
endif()
add_library(nanodbc SHARED src/nanodbc.cpp)
set_target_properties(nanodbc PROPERTIES
	COMPILE_FLAGS "${ODBC_COMPILE_FLAGS}"
	LIBRARY_OUTPUT_DIRECTORY "lib"
)
target_link_libraries(nanodbc ${Boost_LIBRARIES} ${ODBC_LIBRARIES})

if (NANODBC_INSTALL)
	install(FILES src/nanodbc.h DESTINATION include)
	install(TARGETS nanodbc LIBRARY DESTINATION lib)
	message(STATUS "Target install: Enabled")
else()
	message(STATUS "Target install: Disabled")
endif()

########################################
## unit tests
########################################
if (NANODBC_TEST)
	enable_testing()
	add_subdirectory(test)
	add_test(NAME test COMMAND tests)
	add_custom_target(check
		COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process --output-on-failure
		DEPENDS tests)
		message(STATUS "Target test: Enabled")
	else()
		message(STATUS "Target test: Disabled")

endif()
