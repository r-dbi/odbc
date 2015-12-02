set(examples northwind usage rowset_iteration)

include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/src)

foreach(example ${examples})
	add_executable(example_${example} ${example}.cpp)
	if (NANODBC_STATIC)
		target_link_libraries(example_${example} nanodbc ${Boost_LIBRARIES} ${ODBC_LIBRARIES})
	else()
		target_link_libraries(example_${example} nanodbc ${Boost_LIBRARIES})
	endif()
endforeach()