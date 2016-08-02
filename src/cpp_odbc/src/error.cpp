/**
 *  @file error.cpp
 *  @date Jan 24, 2012
 *  @author klein
 *  @brief
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include "cpp_odbc/error.h"
#include "cpp_odbc/level2/diagnostic_record.h"
#include <boost/format.hpp>

using cpp_odbc::error;

error::error(cpp_odbc::level2::diagnostic_record const & record) :
	std::runtime_error((boost::format("ODBC error\nstate: %1%\nnative error code: %2%\nmessage: %3%")
				% record.odbc_status_code % record.native_error_code % record.message).str())
{
}

error::error(std::string const & message) :
	std::runtime_error(message)
{
}


error::~error() throw()
{}
