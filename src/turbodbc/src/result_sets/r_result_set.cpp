#include <turbodbc/result_sets/r_result_set.h>

#include <turbodbc/make_field_translator.h>

#include <sql.h>
#include <Rcpp.h>
#include <boost/any.hpp>
#include <deque>

using namespace Rcpp;

namespace turbodbc { namespace result_sets {

namespace {

	double make_date(SQL_DATE_STRUCT const & date)
	{
	return Rcpp::Date(date.year, date.month, date.day).getDate();
	}

	double make_timestamp(SQL_TIMESTAMP_STRUCT const & ts)
	{
		tm t;
		t.tm_sec = t.tm_min = t.tm_hour = t.tm_isdst = 0;

		t.tm_year = ts.year - 1900;
		t.tm_mon = ts.month;
		t.tm_mday = ts.day;
		t.tm_hour = ts.hour;
		t.tm_min = ts.minute;
		t.tm_sec = ts.second;

		return Rcpp::mktime00(t) + ts.fraction;
	}

void append_buffer(boost::any& out, turbodbc::type_code code, size_t result_size, cpp_odbc::multi_value_buffer const & buffer)
{
		for (std::size_t i = 0; i < result_size; ++i) {
			switch (code) {
				case type_code::boolean: {
					boost::any_cast<std::deque<bool>>(&out)->push_back(*reinterpret_cast<bool const*>(buffer[i].data_pointer));
					break;
				}
				case type_code::integer: {
					boost::any_cast<std::deque<long>>(&out)->push_back(*reinterpret_cast<long const*>(buffer[i].data_pointer));
					break;
				}
				case type_code::floating_point: {
					boost::any_cast<std::deque<double>>(&out)->push_back(*reinterpret_cast<double const*>(buffer[i].data_pointer));
					break;
				}
				case type_code::string: {
					boost::any_cast<std::deque<std::string>>(&out)->push_back(reinterpret_cast<char const*>(buffer[i].data_pointer));
					break;
				}
				case type_code::date:
					boost::any_cast<std::deque<double>>(&out)->push_back(make_date(*reinterpret_cast<SQL_DATE_STRUCT const *>(buffer[i].data_pointer)));
					break;
				case type_code::timestamp:
					boost::any_cast<std::deque<double>>(&out)->push_back(make_timestamp(*reinterpret_cast<SQL_TIMESTAMP_STRUCT const *>(buffer[i].data_pointer)));
					break;
				default:
					throw std::logic_error("Encountered unsupported type code");
			}
		}
	}

List convert_to_r(std::deque<boost::any> const & out, std::vector<column_info> info)
{
	List result = List(info.size());

	for (std::size_t i = 0; i != info.size(); ++i) {
			switch (info[i].type) {
				case type_code::boolean: {
					result[i] = LogicalVector(boost::any_cast<std::deque<bool>>(&out[i])->begin(), boost::any_cast<std::deque<bool>>(&out[i])->end());
					break;
				}
				case type_code::integer: {
					result[i] = IntegerVector(boost::any_cast<std::deque<long>>(&out[i])->begin(), boost::any_cast<std::deque<long>>(&out[i])->end());
					break;
				}
				case type_code::floating_point: {
					result[i] = NumericVector(boost::any_cast<std::deque<double>>(&out[i])->begin(), boost::any_cast<std::deque<double>>(&out[i])->end());
					break;
				}
				case type_code::string: {
					result[i] = CharacterVector(boost::any_cast<std::deque<std::string>>(&out[i])->begin(), boost::any_cast<std::deque<std::string>>(&out[i])->end());
					break;
				}
				case type_code::date: {
					NumericVector vector = NumericVector(boost::any_cast<std::deque<double>>(&out[i])->begin(), boost::any_cast<std::deque<double>>(&out[i])->end());
					vector.attr("class") = "date";
					result[i] = vector;
					break;
				}
				case type_code::timestamp: {
					NumericVector vector = NumericVector(boost::any_cast<std::deque<double>>(&out[i])->begin(), boost::any_cast<std::deque<double>>(&out[i])->end());
					vector.attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
					vector.attr("tzone") = "UTC";
					result[i] = vector;
					break;
				}
				default:
					throw std::logic_error("Encountered unsupported type code");
			}
	}
	return result;
}

	boost::any declare_column(turbodbc::type_code code, std::size_t size)
	{
		switch (code) {
			case type_code::boolean: {
				return std::deque<bool>();
			}
			case type_code::integer: {
				return std::deque<long>();
			}
			case type_code::floating_point: {
				return std::deque<double>();
			}
			case type_code::string: {
				return std::deque<std::string>();
			}
			case type_code::date: {
				return std::deque<double>();
			}
			case type_code::timestamp: {
				return std::deque<double>();
			}
			default:
				throw std::logic_error("Encountered unsupported type code");
		}
	}
}

r_result_set::r_result_set(result_set & base) :
	base_result_(base)
{
	for (auto const & info : base_result_.get_column_info()) {
		types_.emplace_back(info.type);
	}
}

std::vector<column_info> r_result_set::get_column_info() const
{
	return base_result_.get_column_info();
}

RObject r_result_set::fetch_all() const
{

	auto const column_info = base_result_.get_column_info();
	auto const n_columns = column_info.size();

	std::deque<boost::any> columns(n_columns);
	auto const buffers = base_result_.get_buffers();

	size_t rows_in_batch, total_rows;
	total_rows = 0;
	rows_in_batch = base_result_.fetch_next_batch();

	CharacterVector names(n_columns);
	for (std::size_t i = 0; i != n_columns; ++i) {
		names[i] = column_info[i].name;
		columns[i] = declare_column(column_info[i].type, rows_in_batch);
	}

	while (rows_in_batch != 0) {
		for (std::size_t i = 0; i != n_columns; ++i) {
			append_buffer(columns[i], column_info[i].type, rows_in_batch, buffers[i]);
			names[i] = column_info[i].name;
		}
		total_rows += rows_in_batch;
		rows_in_batch = base_result_.fetch_next_batch();
	}
	List result = convert_to_r(columns, column_info);
	result.attr("names") = names;
	result.attr("class") = CharacterVector::create("data.frame");
	result.attr("row.names") = IntegerVector::create(NA_INTEGER, -(total_rows));
	return result;
}

} }
