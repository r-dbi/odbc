add_custom_target(examples DEPENDS examples)
set(examples northwind usage rowset_iteration)

include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/src)

foreach(example ${examples})
	add_executable(example_${example} ${example}.cpp)
	if (NANODBC_STATIC)
		target_link_libraries(example_${example} nanodbc ${ODBC_LIBRARIES})
	else()
		target_link_libraries(example_${example} nanodbc "${ODBC_LINK_FLAGS}")
	endif()
	add_dependencies(examples example_${example})
endforeach()
