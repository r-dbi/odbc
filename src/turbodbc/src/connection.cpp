#include "turbodbc/connection.h"
#include "turbodbc/shared_ptr.h"
#include <sqlext.h>

namespace turbodbc {

connection::connection(std::shared_ptr<cpp_odbc::connection const> low_level_connection) :
  connection_(low_level_connection)
	//active_cursor_(nullptr)
{
	//connection_ = make_shared_ptr<cpp_odbc::connection const>(low_level_connection);
	connection_->set_attribute(SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_ON);
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

std::shared_ptr<cpp_odbc::connection const> connection::get_connection() const
{
	return connection_;
}

}
