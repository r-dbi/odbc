#include <turbodbc/cursor.h>
#include <turbodbc/make_description.h>
#include <turbodbc/result_sets/bound_result_set.h>

#include <cpp_odbc/statement.h>
#include <cpp_odbc/error.h>

#include <boost/variant/get.hpp>
#include <sqlext.h>
#include <stdexcept>

#include <cstring>
#include <sstream>
#include <boost/make_shared.hpp>


namespace turbodbc {

cursor::cursor(boost::shared_ptr<cpp_odbc::connection const> connection,
               std::size_t rows_to_buffer,
               std::size_t parameter_sets_to_buffer,
               bool use_async_io) :
	connection_(connection),
	rows_to_buffer_(rows_to_buffer),
	parameter_sets_to_buffer_(parameter_sets_to_buffer),
	use_async_io_(use_async_io),
	query_()
{
}

cursor::~cursor() = default;

void cursor::prepare(std::string const & sql)
{
	results_.reset();
	query_.reset();
	auto statement = connection_->make_statement();
	statement->prepare(sql);
	query_ = boost::make_shared<query>(statement, rows_to_buffer_, parameter_sets_to_buffer_, use_async_io_);
}

void cursor::execute()
{
	query_->execute();
	auto raw_result_set = query_->get_results();
	if (raw_result_set) {
		results_ = boost::make_shared<result_sets::r_result_set>(*raw_result_set);
	}
}

boost::shared_ptr<result_sets::r_result_set> cursor::get_result_set() const
{
	return results_;
}

void cursor::add_parameter_set(std::vector<nullable_field> const & parameter_set)
{
	query_->add_parameter_set(parameter_set);
}

long cursor::get_row_count()
{
	return query_->get_row_count();
}

boost::shared_ptr<cpp_odbc::connection const> cursor::get_connection() const
{
	return connection_;
}

boost::shared_ptr<turbodbc::query> cursor::get_query()
{
	return query_;
}

boost::shared_ptr<result_sets::r_result_set> cursor::get_tables() const
{
	auto statement = connection_->make_statement();
	statement->get_tables("", "", "", "");
	auto rs = result_sets::bound_result_set(statement, rows_to_buffer_);

	auto results = boost::make_shared<result_sets::r_result_set>(rs);
	return results;
}

}
