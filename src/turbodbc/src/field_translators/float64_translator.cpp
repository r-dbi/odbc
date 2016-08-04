#include <turbodbc/field_translators/float64_translator.h>

#include <boost/variant/get.hpp>
#include <sqlext.h>

namespace turbodbc { namespace field_translators {

float64_translator::float64_translator() = default;

float64_translator::~float64_translator() = default;

field float64_translator::do_make_field(char const * data_pointer) const
{
	return {*reinterpret_cast<double const *>(data_pointer)};
}

void float64_translator::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	*reinterpret_cast<double *>(element.data_pointer) = boost::get<double>(value);
	element.indicator = sizeof(double);
}

} }
