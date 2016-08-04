#include <turbodbc/descriptions/floating_point_description.h>

#include <sqlext.h>

#include <boost/variant/get.hpp>
#include <cstring>

namespace turbodbc {

floating_point_description::floating_point_description() = default;

floating_point_description::floating_point_description(std::string name, bool supports_null) :
	description(std::move(name), supports_null)
{
}

floating_point_description::~floating_point_description() = default;

std::size_t floating_point_description::do_element_size() const
{
	return sizeof(double);
}

SQLSMALLINT floating_point_description::do_column_c_type() const
{
	return SQL_C_DOUBLE;
}

SQLSMALLINT floating_point_description::do_column_sql_type() const
{
	return SQL_DOUBLE;
}

void floating_point_description::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	auto const as_double = boost::get<double>(value);
	memcpy(element.data_pointer, &as_double, element_size());
	element.indicator = element_size();
}

type_code floating_point_description::do_get_type_code() const
{
	return type_code::floating_point;
}

}
