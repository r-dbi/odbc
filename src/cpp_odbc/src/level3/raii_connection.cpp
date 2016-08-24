/**
 *  @file raii_connection.cpp
 *  @date 21.03.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-12-05 08:55:14 +0100 (Fr, 05 Dez 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21240 $
 *
 */

#include "cpp_odbc/level3/raii_connection.h"

#include "cpp_odbc/level3/raii_statement.h"
#include "cpp_odbc/level3/raii_environment.h"

#include "cpp_odbc/level2/api.h"
#include "cpp_odbc/level2/handles.h"

#include <boost/format.hpp>

#include <mutex>

namespace {
	// this lock should be used whenever a connection is connected/disconnected
	static std::mutex create_destroy_mutex;

	// raii just for connection handle
	struct raii_handle {
		std::shared_ptr<cpp_odbc::level2::api const> api;
		cpp_odbc::level2::connection_handle handle;

		raii_handle(std::shared_ptr<cpp_odbc::level2::api const> api,
				cpp_odbc::level2::environment_handle const & environment) :
			api(api),
			handle(api->allocate_connection_handle(environment))
		{
		}

		~raii_handle()
		{
			api->free_handle(handle);
		}
	};
}

namespace cpp_odbc { namespace level3 {

struct raii_connection::intern {
	std::shared_ptr<raii_environment const> environment;
	std::shared_ptr<cpp_odbc::level2::api const> api;
	raii_handle handle;

	intern(
			std::shared_ptr<raii_environment const> environment,
			std::string const & connection_string
		) :
		environment(environment),
		api(environment->get_api()),
		handle(api, environment->get_handle())
	{
		thread_safe_establish_connection(connection_string);
	}

	~intern()
	{
		thread_safe_disconnect();
	}

private:

	void thread_safe_establish_connection(std::string const & data_source_name)
	{
		std::lock_guard<std::mutex> guard(create_destroy_mutex);
		api->establish_connection(handle.handle, data_source_name);
	}

	void thread_safe_disconnect()
	{
		std::lock_guard<std::mutex> guard(create_destroy_mutex);
		api->disconnect(handle.handle);
	}
};


raii_connection::raii_connection(std::shared_ptr<raii_environment const> environment, std::string const & connection_string) :
	impl_(new raii_connection::intern(environment, connection_string))
{
}

std::shared_ptr<level2::api const> raii_connection::get_api() const
{
	return impl_->api;
}

level2::connection_handle const & raii_connection::get_handle() const
{
	return impl_->handle.handle;
}

std::shared_ptr<statement const> raii_connection::do_make_statement() const
{
	auto as_raii_connection = std::dynamic_pointer_cast<raii_connection const>(shared_from_this());
	return std::make_shared<raii_statement const>(as_raii_connection);
}

void raii_connection::do_set_attribute(SQLINTEGER attribute, long value) const
{
	impl_->api->set_connection_attribute(impl_->handle.handle, attribute, value);
}

void raii_connection::do_commit() const
{
	impl_->api->end_transaction(impl_->handle.handle, SQL_COMMIT);
}

void raii_connection::do_rollback() const
{
	impl_->api->end_transaction(impl_->handle.handle, SQL_ROLLBACK);
}

std::string raii_connection::do_get_string_info(SQLUSMALLINT info_type) const
{
	return impl_->api->get_string_connection_info(impl_->handle.handle, info_type);
}

SQLUINTEGER raii_connection::do_get_integer_info(SQLUSMALLINT info_type) const
{
	return impl_->api->get_integer_connection_info(impl_->handle.handle, info_type);
}

raii_connection::~raii_connection() = default;

} }
