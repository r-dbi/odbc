/**
 *  @file environment.cpp
 *  @date 16.05.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-05-16 13:39:31 +0200 (Fr, 16 Mai 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 19531 $
 *
 */

#include "cpp_odbc/environment.h"

namespace cpp_odbc {

environment::environment() = default;
environment::~environment() = default;

std::shared_ptr<connection const> environment::make_connection(std::string const & connection_string) const
{
	return do_make_connection(connection_string);
}

void environment::set_attribute(SQLINTEGER attribute, long value) const
{
	do_set_attribute(attribute, value);
}



}
