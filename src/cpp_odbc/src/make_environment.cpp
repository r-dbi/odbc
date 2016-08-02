/**
 *  @file make_environment.cpp
 *  @date 12.12.2014
 *  @author mkoenig
 *  @brief
 *
 *  $LastChangedDate$
 *  $LastChangedBy$
 *  $LastChangedRevision$
 *
 */

#include "cpp_odbc/make_environment.h"

#include "cpp_odbc/level1/unixodbc_backend.h"
#include "cpp_odbc/level1/unixodbc_backend_debug.h"
#include "cpp_odbc/level2/level1_connector.h"
#include "cpp_odbc/level3/raii_environment.h"
#include <boost/make_shared.hpp>

namespace cpp_odbc {

boost::shared_ptr<environment> make_environment()
{
	boost::shared_ptr<level1::unixodbc_backend const> level1_api = boost::make_shared<level1::unixodbc_backend const>();
	boost::shared_ptr<level2::level1_connector const> level2_api = boost::make_shared<level2::level1_connector const>(level1_api);
	return boost::make_shared<level3::raii_environment>(level2_api);
}

boost::shared_ptr<environment> make_debug_environment()
{
	auto level1_api = boost::make_shared<level1::unixodbc_backend_debug const>();
	auto level2_api = boost::make_shared<level2::level1_connector const>(level1_api);
	return boost::make_shared<level3::raii_environment>(level2_api);
}

}
