#pragma once

#include <cpp_odbc/connection.h>
#include <turbodbc/query.h>
#include <turbodbc/column_info.h>
#include <memory>
#include "result_sets/r_result_set.h"
#include <boost/shared_ptr.hpp>

namespace turbodbc {

/**
 * TODO: Cursor needs proper unit tests
 */
class cursor {
public:
	cursor(boost::shared_ptr<cpp_odbc::connection const> connection,
		   std::size_t rows_to_buffer,
		   std::size_t parameter_sets_to_buffer,
		   bool use_async_io);

	void prepare(std::string const & sql);
	void execute();
	void add_parameter_set(std::vector<nullable_field> const & parameter_set);

	long get_row_count();

	boost::shared_ptr<result_sets::r_result_set> get_result_set() const;

	boost::shared_ptr<cpp_odbc::connection const> get_connection() const;

	boost::shared_ptr<turbodbc::query> get_query();

	~cursor();

private:
	boost::shared_ptr<cpp_odbc::connection const> connection_;
	std::size_t rows_to_buffer_;
	std::size_t parameter_sets_to_buffer_;
	bool use_async_io_;
	boost::shared_ptr<turbodbc::query> query_;
	boost::shared_ptr<result_sets::r_result_set> results_;
};

}
