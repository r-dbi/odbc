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

cursor connection::make_cursor()
{
	cursor c = cursor(shared_from_this(), rows_to_buffer, parameter_sets_to_buffer, use_async_io);
	active_cursor_ = &c;
	return c;
}

bool connection::is_current_result(const cursor* c) const
{
	return active_cursor_ == c;
}

boost::shared_ptr<cpp_odbc::connection const> connection::get_connection() const
{
	return connection_;
}

}
