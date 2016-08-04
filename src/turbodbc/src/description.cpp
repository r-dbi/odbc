#include <turbodbc/description.h>

namespace turbodbc {

description::description() :
	name_("parameter"),
	supports_null_(true)
{
}

description::description(std::string name, bool supports_null) :
	name_(std::move(name)),
	supports_null_(supports_null)
{
}

description::~description() = default;

std::size_t description::element_size() const
{
	return do_element_size();
}

SQLSMALLINT description::column_c_type() const
{
	return do_column_c_type();
}

SQLSMALLINT description::column_sql_type() const
{
	return do_column_sql_type();
}

void description::set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	do_set_field(element, value);
}

type_code description::get_type_code() const
{
	return do_get_type_code();
}

std::string const & description::name() const
{
	return name_;
}

bool description::supports_null_values() const
{
	return supports_null_;
}

}
