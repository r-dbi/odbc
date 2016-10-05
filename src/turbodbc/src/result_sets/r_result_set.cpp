#include <turbodbc/result_sets/r_result_set.h>

#include <turbodbc/make_field_translator.h>

#ifdef _WIN32
#undef Realloc
#undef Free
#include <windows.h>
#endif
#include <sql.h>
#include <Rcpp.h>
#include <boost/any.hpp>

using namespace Rcpp;

namespace turbodbc { namespace result_sets {

namespace {

	using nullable_string = boost::optional<std::string>;

	double make_date(SQL_DATE_STRUCT const & date)
	{
	return Rcpp::Date(date.year - 1900, date.month, date.day).getDate();
	}

	double make_timestamp(SQL_TIMESTAMP_STRUCT const & ts)
	{
		tm t;
		t.tm_sec = t.tm_min = t.tm_hour = t.tm_isdst = 0;

		t.tm_year = ts.year - 1900;
		t.tm_mon = ts.month - 1;
		t.tm_mday = ts.day;
		t.tm_hour = ts.hour;
		t.tm_min = ts.minute;
		t.tm_sec = ts.second;

		return Rcpp::mktime00(t) + ts.fraction;
	}

void append_buffer(boost::any& out, turbodbc::type_code code, size_t result_size, cpp_odbc::multi_value_buffer const & buffer, size_t start = 0)
{
		for (std::size_t i = 0; i < result_size; ++i) {
			switch (code) {
				case type_code::boolean: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<int>>(&out)->push_back(NA_LOGICAL);
					} else {
						boost::any_cast<std::vector<int>>(&out)->push_back(*reinterpret_cast<int const*>(buffer[i + start].data_pointer));
					}
					break;
				}
				case type_code::integer: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<long>>(&out)->push_back(NA_INTEGER);
					} else {
						boost::any_cast<std::vector<long>>(&out)->push_back(*reinterpret_cast<long const*>(buffer[i + start].data_pointer));
					}
					break;
				}
				case type_code::floating_point: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<double>>(&out)->push_back(NA_REAL);
					} else {
						boost::any_cast<std::vector<double>>(&out)->push_back(*reinterpret_cast<double const*>(buffer[i + start].data_pointer));
					}
					break;
				}
				case type_code::string: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<nullable_string>>(&out)->push_back({});
					} else {
						boost::any_cast<std::vector<nullable_string>>(&out)->push_back(std::string(reinterpret_cast<char const*>(buffer[i + start].data_pointer)));
					}
					break;
				}
				case type_code::date: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<double>>(&out)->push_back(NA_REAL);
					} else {
						boost::any_cast<std::vector<double>>(&out)->push_back(make_date(*reinterpret_cast<SQL_DATE_STRUCT const *>(buffer[i + start].data_pointer)));
					}
					break;
				}
				case type_code::timestamp: {
					if (buffer[i + start].indicator == SQL_NULL_DATA) {
						boost::any_cast<std::vector<double>>(&out)->push_back(NA_REAL);
					} else {
						boost::any_cast<std::vector<double>>(&out)->push_back(make_timestamp(*reinterpret_cast<SQL_TIMESTAMP_STRUCT const *>(buffer[i + start].data_pointer)));
					}
					break;
				}
				default:
					throw std::logic_error("Encountered unsupported type code");
			}
		}
	}

List convert_to_r(std::vector<boost::any> const & out, std::vector<column_info> info)
{
	List result = List(info.size());

	for (std::size_t i = 0; i != info.size(); ++i) {
			switch (info[i].type) {
				case type_code::boolean: {
					result[i] = LogicalVector(boost::any_cast<std::vector<int>>(&out[i])->begin(), boost::any_cast<std::vector<int>>(&out[i])->end());
					break;
				}
				case type_code::integer: {
					result[i] = IntegerVector(boost::any_cast<std::vector<long>>(&out[i])->begin(), boost::any_cast<std::vector<long>>(&out[i])->end());
					break;
				}
				case type_code::floating_point: {
					result[i] = NumericVector(boost::any_cast<std::vector<double>>(&out[i])->begin(), boost::any_cast<std::vector<double>>(&out[i])->end());
					break;
				}
				case type_code::string: {
					auto data = boost::any_cast<std::vector<nullable_string>>(&out[i]);
					auto out = CharacterVector(data->size());
					for (size_t j = 0; j < data->size(); ++j) {
						if ((*data)[j] == boost::none) {
							out[j] = NA_STRING;
						} else {
							SET_STRING_ELT(out, j, Rf_mkCharCE(boost::get<std::string>((*data)[j]).c_str(), CE_UTF8));
						}
					}
					result[i] = out;
					break;
				}
				case type_code::date: {
					NumericVector vector = NumericVector(boost::any_cast<std::vector<double>>(&out[i])->begin(), boost::any_cast<std::vector<double>>(&out[i])->end());
					vector.attr("class") = "Date";
					result[i] = vector;
					break;
				}
				case type_code::timestamp: {
					NumericVector vector = NumericVector(boost::any_cast<std::vector<double>>(&out[i])->begin(), boost::any_cast<std::vector<double>>(&out[i])->end());
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
				return std::vector<int>();
			}
			case type_code::integer: {
				return std::vector<long>();
			}
			case type_code::floating_point: {
				return std::vector<double>();
			}
			case type_code::string: {
				return std::vector<nullable_string>();
			}
			case type_code::date: {
				return std::vector<double>();
			}
			case type_code::timestamp: {
				return std::vector<double>();
			}
			default:
				throw std::logic_error("Encountered unsupported type code");
		}
	}
}

r_result_set::r_result_set(result_set & base) :
	base_result_(base),
	has_completed_(false),
	rows_in_batch_(0),
	row_offset_(0),
	total_rows_(0)
{
	for (auto const & info : base_result_.get_column_info()) {
		types_.emplace_back(info.type);
	}
}

std::vector<column_info> r_result_set::get_column_info() const
{
	return base_result_.get_column_info();
}

List r_result_set::fetch(size_t n) const
{
	if (has_completed_) {
	return List();
	}
	auto const column_info = base_result_.get_column_info();
	auto const n_columns = column_info.size();

	std::vector<boost::any> columns(n_columns);

	if (row_offset_ == 0) {
		buffers_ = base_result_.get_buffers();
		rows_in_batch_ = base_result_.fetch_next_batch();
		row_offset_ = 0;
	}

	size_t rows = 0;
	size_t batch_size = n - rows < (rows_in_batch_ - row_offset_) ? n - rows : (rows_in_batch_ - row_offset_);

	CharacterVector names(n_columns);
	for (std::size_t i = 0; i != n_columns; ++i) {
		names[i] = column_info[i].name;
		columns[i] = declare_column(column_info[i].type, batch_size);
	}

	while (rows_in_batch_ != 0) {
		for (std::size_t i = 0; i != n_columns; ++i) {
			append_buffer(columns[i], column_info[i].type, batch_size, buffers_[i], row_offset_);
			names[i] = column_info[i].name;
		}
		rows += batch_size;

		// break if we have read enough rows to reach n and we have not reached the
		// end of the batch
		if (rows >= n && (row_offset_ + batch_size != rows_in_batch_)) {
			row_offset_ += batch_size;
			break;
		}

		rows_in_batch_ = base_result_.fetch_next_batch();
		row_offset_ = 0;
		batch_size = n - rows < (rows_in_batch_ - row_offset_) ? n - rows : (rows_in_batch_ - row_offset_);
	}

	if (rows_in_batch_ == 0) {
		has_completed_ = true;
	}

	total_rows_ += rows;
	List result = convert_to_r(columns, column_info);
	result.attr("names") = names;
	result.attr("class") = CharacterVector::create("data.frame");
	result.attr("row.names") = IntegerVector::create(NA_INTEGER, -(rows));

	return result;
}

size_t r_result_set::get_rows_returned() const
{
	return total_rows_;
}

bool r_result_set::has_completed() const
{
	return has_completed_;
}

} }

