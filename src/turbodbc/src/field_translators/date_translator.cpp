#include <turbodbc/field_translators/date_translator.h>

#include <boost/variant/get.hpp>

#include <sql.h>


namespace turbodbc { namespace field_translators {

date_translator::date_translator() = default;

date_translator::~date_translator() = default;

field date_translator::do_make_field(char const * data_pointer) const
{
	auto const date = reinterpret_cast<SQL_DATE_STRUCT const *>(data_pointer);
	return {boost::gregorian::date(date->year, date->month, date->day)};
}

void date_translator::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	auto const & as_date = boost::get<boost::gregorian::date>(value);
	auto destination = reinterpret_cast<SQL_DATE_STRUCT *>(element.data_pointer);

	destination->year = as_date.year();
	destination->month = as_date.month();
	destination->day = as_date.day();

	element.indicator = sizeof(SQL_DATE_STRUCT);
}

} }
