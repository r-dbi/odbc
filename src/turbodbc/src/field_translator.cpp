#include <turbodbc/field_translator.h>

#include <sql.h>

namespace turbodbc {

field_translator::field_translator() = default;

field_translator::~field_translator() = default;

nullable_field field_translator::make_field(cpp_odbc::buffer_element const & element) const
{
	if (element.indicator == SQL_NULL_DATA) {
		return {};
	} else {
		return do_make_field(element.data_pointer);
	}
}

void field_translator::set_field(cpp_odbc::writable_buffer_element & element, nullable_field const & value) const
{
	if (value) {
		do_set_field(element, *value);
	} else {
		element.indicator = SQL_NULL_DATA;
	}
}

}
