#include <turbodbc/field_translators/timestamp_translator.h>

#include <boost/variant/get.hpp>

#include <sql.h>


namespace turbodbc { namespace field_translators {

timestamp_translator::timestamp_translator() = default;

timestamp_translator::~timestamp_translator() = default;

field timestamp_translator::do_make_field(char const * data_pointer) const
{
	auto const ts = reinterpret_cast<SQL_TIMESTAMP_STRUCT const *>(data_pointer);
	// map SQL nanosecond precision to posix_time microsecond precision
	long const adjusted_fraction = ts->fraction / 1000;
	return {boost::posix_time::ptime{
										{static_cast<short unsigned int>(ts->year), ts->month, ts->day},
										{ts->hour, ts->minute, ts->second, adjusted_fraction}
									}
			};
}

void timestamp_translator::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
{
	auto const & as_ts = boost::get<boost::posix_time::ptime>(value);
	auto const & date = as_ts.date();
	auto const & time = as_ts.time_of_day();
	auto destination = reinterpret_cast<SQL_TIMESTAMP_STRUCT *>(element.data_pointer);

	destination->year = date.year();
	destination->month = date.month();
	destination->day = date.day();
	destination->hour = time.hours();
	destination->minute = time.minutes();
	destination->second = time.seconds();
	// map posix_time microsecond precision to SQL nanosecond precision
	destination->fraction = time.fractional_seconds() * 1000;

	element.indicator = sizeof(SQL_TIMESTAMP_STRUCT);
}

} }
