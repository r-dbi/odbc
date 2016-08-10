#include <turbodbc/result_sets/r_result_set.h>

#include <turbodbc/make_field_translator.h>

#include <sql.h>
#include <Rcpp.h>

using namespace Rcpp;

namespace turbodbc { namespace result_sets {

namespace {

	double make_date(SQL_DATE_STRUCT const & date)
	{
		//return boost::python::object(boost::python::handle<>(PyDate_FromDate(date.year,
																																				 //date.month,
																																				 //date.day)));

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

	RObject resize_column(RObject old, turbodbc::type_code code, size_t new_size)
	{
		RObject out = Rf_lengthgets(old, new_size);
			switch (code) {
				case type_code::date: {
																out.attr("class") = old.attr("class");
																break;
															}
				case type_code::timestamp: {
																	 out.attr("class") = old.attr("class");
																	 out.attr("tzone") = "UTC";
																	 break;
																	 }
			default: {}
			}
			return out;
	}


	SEXP fill_column(SEXP out, turbodbc::type_code code, size_t size_so_far, size_t result_size, cpp_odbc::multi_value_buffer const & buffer)
	{
		out = resize_column(out, code, size_so_far + result_size);
		for (std::size_t i = 0; i < result_size; ++i) {
			switch (code) {
				case type_code::boolean: {
																	 LOGICAL(out)[size_so_far + i] = *reinterpret_cast<bool const*>(buffer[i].data_pointer);
																	 break;
																 }
				case type_code::integer: {
																	 INTEGER(out)[size_so_far + i] = *reinterpret_cast<long const*>(buffer[i].data_pointer);
																	 break;
																 }
				case type_code::floating_point: {
																					REAL(out)[size_so_far + i] = *reinterpret_cast<double const*>(buffer[i].data_pointer);
																					break;
																				}
				case type_code::string: {
																	SET_STRING_ELT(out, size_so_far + i, Rf_mkCharCE(reinterpret_cast<char const*>(buffer[i].data_pointer), CE_UTF8));
																	break;
																}
				case type_code::date:
																REAL(out)[size_so_far + i] = make_date(*reinterpret_cast<SQL_DATE_STRUCT const *>(buffer[i].data_pointer));
																break;
				case type_code::timestamp:
																REAL(out)[size_so_far + i] = make_timestamp(*reinterpret_cast<SQL_TIMESTAMP_STRUCT const *>(buffer[i].data_pointer));
																break;
				default:
																throw std::logic_error("Encountered unsupported type code");
			}
		}
		return out;
	}

	RObject declare_column(turbodbc::type_code code, std::size_t size)
	{
		switch (code) {
			case type_code::boolean: {
																 return LogicalVector(size);
															 }
			case type_code::integer: {
																 return IntegerVector(size);
				}
			case type_code::floating_point: {
																 return NumericVector(size);
																			}
			case type_code::string: {
																return CharacterVector(size);
															}
			case type_code::date: {
															NumericVector out = NumericVector(size);
															out.attr("class") = "date";
															return out;
														}
			case type_code::timestamp: {
															NumericVector out = NumericVector(size);
															out.attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
															out.attr("tzone") = "UTC";
															return out;
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

RObject r_result_set::fetch_next_batch() const
{
	auto const column_info = base_result_.get_column_info();
	auto const n_columns = column_info.size();

	List columns(n_columns);
	auto const buffers = base_result_.get_buffers();

	size_t rows_in_batch;
	rows_in_batch = base_result_.fetch_next_batch();

	CharacterVector names(n_columns);
	for (std::size_t i = 0; i != n_columns; ++i) {
		names[i] = column_info[i].name;
		columns[i] = declare_column(column_info[i].type, rows_in_batch);
		columns[i] = fill_column(columns[i], column_info[i].type, 0, rows_in_batch, buffers[i]);
	}

	columns.attr("names") = names;
	columns.attr("class") = CharacterVector::create("tbl_df", "tbl", "data.frame");
	columns.attr("row.names") = IntegerVector::create(NA_INTEGER, -(rows_in_batch));
	return columns;
}

RObject r_result_set::fetch_all() const
{

	auto const column_info = base_result_.get_column_info();
	auto const n_columns = column_info.size();

	List columns(n_columns);
	auto const buffers = base_result_.get_buffers();

	size_t rows_in_batch, rows_so_far;
	rows_so_far = 0;
	rows_in_batch = base_result_.fetch_next_batch();

	CharacterVector names(n_columns);
	for (std::size_t i = 0; i != n_columns; ++i) {
		names[i] = column_info[i].name;
		columns[i] = declare_column(column_info[i].type, rows_in_batch);
	}

	while (rows_in_batch != 0) {
		for (std::size_t i = 0; i != n_columns; ++i) {
			columns[i] = fill_column(columns[i], column_info[i].type, rows_so_far, rows_in_batch, buffers[i]);
			names[i] = column_info[i].name;
		}
		rows_so_far += rows_in_batch;
		rows_in_batch = base_result_.fetch_next_batch();
	}

	columns.attr("names") = names;
	columns.attr("class") = CharacterVector::create("tbl_df", "tbl", "data.frame");
	columns.attr("row.names") = IntegerVector::create(NA_INTEGER, -(rows_so_far));
	return columns;
}
} }
