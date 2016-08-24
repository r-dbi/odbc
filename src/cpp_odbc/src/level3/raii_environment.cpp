/**
 *  @file raii_environment.cpp
 *  @date 13.03.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include "cpp_odbc/level3/raii_environment.h"
#include "cpp_odbc/level3/raii_connection.h"
#include "cpp_odbc/level2/handles.h"
#include "cpp_odbc/level2/api.h"

#include "sqlext.h"

#include <stdexcept>

namespace cpp_odbc { namespace level3 {

struct raii_environment::intern {
	std::shared_ptr<level2::api const> api;
	level2::environment_handle handle;

	intern(std::shared_ptr<level2::api const> in_api) :
		api(std::move(in_api)),
		handle(api->allocate_environment_handle())
	{
		api->set_environment_attribute(handle, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3);
	}

	~intern()
	{
		api->free_handle(handle);
	}
};

raii_environment::raii_environment(std::shared_ptr<level2::api const> api) :
	impl_(new raii_environment::intern(std::move(api)))
{
}

std::shared_ptr<level2::api const> raii_environment::get_api() const
{
	return impl_->api;
}

level2::environment_handle const & raii_environment::get_handle() const
{
	return impl_->handle;
}

std::shared_ptr<connection const> raii_environment::do_make_connection(std::string const & connection_string) const
{
	auto as_raii_environment = std::dynamic_pointer_cast<raii_environment const>(shared_from_this());
	return std::make_shared<raii_connection const>(as_raii_environment, connection_string);
}

void raii_environment::do_set_attribute(SQLINTEGER attribute, long value) const
{
	impl_->api->set_environment_attribute(impl_->handle, attribute, value);
}

raii_environment::~raii_environment() = default;

} }
