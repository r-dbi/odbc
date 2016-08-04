#include <turbodbc/descriptions/boolean_description.h>

#include <boost/variant/get.hpp>
#include <sqlext.h>

namespace turbodbc {

boolean_description::boolean_description() = default;

boolean_description::boolean_description(std::string name, bool supports_null) :
	description(std::move(name), supports_null)
{
}


boolean_description::~boolean_description() = default;

std::size_t boolean_description::do_element_size() const
{
	return sizeof(char);
}

SQLSMALLINT boolean_description::do_column_c_type() const
{
	return SQL_C_BIT;
}

SQLSMALLINT boolean_description::do_column_sql_type() const
{
	return SQL_BIT;
}

void boolean_description::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	*element.data_pointer = boost::get<bool>(value) ? 1 : 0;
	element.indicator = 1;
}

type_code boolean_description::do_get_type_code() const
{
	return type_code::boolean;
}

}
