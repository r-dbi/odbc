#pragma once

#include <turbodbc/connection.h>
#include <turbodbc/query.h>
#include <turbodbc/column_info.h>
#include <memory>
#include "result_sets/r_result_set.h"
#include <boost/shared_ptr.hpp>
#include <Rcpp.h>

namespace turbodbc {
class connection;

/**
 * TODO: Cursor needs proper unit tests
 */
class cursor {
public:
	cursor(std::shared_ptr<turbodbc::connection const> connection,
		   std::size_t rows_to_buffer,
		   std::size_t parameter_sets_to_buffer,
		   bool use_async_io);

	cursor(boost::shared_ptr<turbodbc::connection const> connection,
		   std::size_t rows_to_buffer,
		   std::size_t parameter_sets_to_buffer,
		   bool use_async_io);

	void prepare(std::string const & sql);
	void execute();
	void add_parameter_set(Rcpp::DataFrame const & df);
	void add_parameter_set(Rcpp::List const & parameter_set);
	void add_parameter_set(std::vector<nullable_field> const & parameter_set);

	long get_row_count();

	boost::shared_ptr<result_sets::r_result_set> get_result_set() const;

	boost::shared_ptr<turbodbc::connection const> get_connection() const;

	boost::shared_ptr<turbodbc::query> get_query();

	Rcpp::List sql_tables(std::string const & catalog_name, std::string const & schema_name, std::string const & table_name, std::string const & table_type);

	bool is_active() const;
	~cursor();

private:
	boost::shared_ptr<turbodbc::connection const> connection_;
	std::size_t rows_to_buffer_;
	std::size_t parameter_sets_to_buffer_;
	bool use_async_io_;
	boost::shared_ptr<turbodbc::query> query_;
	boost::shared_ptr<result_sets::r_result_set> results_;
};

}
