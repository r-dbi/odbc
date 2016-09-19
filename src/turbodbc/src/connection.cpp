#include "turbodbc/connection.h"
#include "turbodbc/shared_ptr.h"
#include <sqlext.h>

namespace turbodbc {

connection::connection(std::shared_ptr<cpp_odbc::connection const> low_level_connection) :
	rows_to_buffer(1000),
	parameter_sets_to_buffer(1000),
	use_async_io(false),
	active_cursor_(nullptr)
{
	connection_ = make_shared_ptr<cpp_odbc::connection const>(low_level_connection);
	connection_->set_attribute(SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF);
}

void connection::commit() const
{
	connection_->commit();
}

void connection::rollback() const
{
	connection_->rollback();
}

void connection::set_active_cursor(const cursor* c) const
{
	active_cursor_ = c;
}

bool connection::is_active_cursor(const cursor* c) const
{
	return active_cursor_ == c;
}

boost::shared_ptr<cpp_odbc::connection const> connection::get_connection() const
{
	return connection_;
}

}
