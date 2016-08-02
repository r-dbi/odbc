/**
 *  @file connection.cpp
 *  @date 16.05.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-05-16 13:39:31 +0200 (Fr, 16 Mai 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 19531 $
 *
 */

#include "cpp_odbc/connection.h"

namespace cpp_odbc {

connection::connection() = default;
connection::~connection() = default;

std::shared_ptr<statement const> connection::make_statement() const
{
	return do_make_statement();
}

void connection::set_attribute(SQLINTEGER attribute, long value) const
{
	do_set_attribute(attribute, value);
}

void connection::commit() const
{
	do_commit();
}

void connection::rollback() const
{
	do_rollback();
}

std::string connection::get_string_info(SQLUSMALLINT info_type) const
{
	return do_get_string_info(info_type);
}

SQLUINTEGER connection::get_integer_info(SQLUSMALLINT info_type) const
{
	return do_get_integer_info(info_type);
}

}
