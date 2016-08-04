#include <turbodbc/descriptions/timestamp_description.h>

#include <sqlext.h>

#include <boost/variant/get.hpp>
#include <cstring>

namespace turbodbc {

timestamp_description::timestamp_description() = default;

timestamp_description::timestamp_description(std::string name, bool supports_null) :
	description(std::move(name), supports_null)
{
}

timestamp_description::~timestamp_description() = default;

std::size_t timestamp_description::do_element_size() const
{
	return sizeof(SQL_TIMESTAMP_STRUCT);
}

SQLSMALLINT timestamp_description::do_column_c_type() const
{
	return SQL_C_TYPE_TIMESTAMP;
}

SQLSMALLINT timestamp_description::do_column_sql_type() const
{
	return SQL_TYPE_TIMESTAMP;
}

void timestamp_description::do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const
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

	element.indicator = element_size();
}

type_code timestamp_description::do_get_type_code() const
{
	return type_code::timestamp;
}

}
