#include <turbodbc/field_translators/boolean_translator.h>

#include <boost/variant/get.hpp>


namespace turbodbc { namespace field_translators {

boolean_translator::boolean_translator() = default;

boolean_translator::~boolean_translator() = default;

field boolean_translator::do_make_field(char const * data_pointer) const
{
	return {static_cast<bool>(*data_pointer)};
}

void boolean_translator::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	*element.data_pointer = boost::get<bool>(value) ? 1 : 0;
	element.indicator = 1;
}

} }
