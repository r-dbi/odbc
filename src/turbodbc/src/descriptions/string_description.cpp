#include <turbodbc/descriptions/string_description.h>

#include <boost/variant/get.hpp>

#include <sqlext.h>
#include <cstring>

namespace turbodbc {

string_description::string_description(std::size_t maximum_length) :
	maximum_length_(maximum_length)
{
}

string_description::string_description(std::string name, bool supports_null, std::size_t maximum_length) :
	description(std::move(name), supports_null),
	maximum_length_(maximum_length)
{
}

string_description::~string_description() = default;

std::size_t string_description::do_element_size() const
{
	return maximum_length_ + 1;
}

SQLSMALLINT string_description::do_column_c_type() const
{
	return SQL_C_CHAR;
}

SQLSMALLINT string_description::do_column_sql_type() const
{
	return SQL_VARCHAR;
}

void string_description::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	auto const & as_string = boost::get<std::string>(value);

	if (as_string.size() <= maximum_length_) {
		auto const length_with_null_termination = as_string.size() + 1;
		std::memcpy(element.data_pointer, as_string.c_str(), length_with_null_termination);
		element.indicator = as_string.size();
	} else {
		throw std::runtime_error("String exceeds maximum length supported by buffer");
	}
}

type_code string_description::do_get_type_code() const
{
	return type_code::string;
}

}
