#include <turbodbc/field_translators/string_translator.h>

#include <boost/variant/get.hpp>

#include <stdexcept>

namespace turbodbc { namespace field_translators {

string_translator::string_translator() = default;

string_translator::~string_translator() = default;

field string_translator::do_make_field(char const * data_pointer) const
{
	return {std::string(data_pointer)};
}

void string_translator::do_set_field(cpp_odbc::writable_buffer_element &, field const &) const
{
	throw std::logic_error("Setting string values not implemented yet!");
}

} }
