#include <turbodbc/result_sets/r_result_set.h>

#include <turbodbc/make_field_translator.h>

#include <sql.h>
#include <Rcpp.h>

using namespace Rcpp;

namespace turbodbc { namespace result_sets {

namespace {

	RObject make_date(SQL_DATE_STRUCT const & date)
	{
		//return boost::python::object(boost::python::handle<>(PyDate_FromDate(date.year,
																																				 //date.month,
																																				 //date.day)));

	return Rcpp::wrap(Rcpp::Date(date.year, date.month, date.day));
	}

	RObject make_timestamp(SQL_TIMESTAMP_STRUCT const & ts)
	{
		// map SQL nanosecond precision to microsecond precision
		//long const adjusted_fraction = ts.fraction / 1000;
		//return boost::python::object(
				//boost::python::handle<>(PyDateTime_FromDateAndTime(ts.year, ts.month, ts.day,
																													 //ts.hour, ts.minute, ts.second, adjusted_fraction))
			//);
		tm t;
		t.tm_year = ts.year;
		t.tm_mon = ts.month;
		t.tm_mday = ts.day;
		t.tm_hour = ts.hour;
		t.tm_min = ts.minute;
		t.tm_sec = ts.second;

		NumericVector out(Rcpp::mktime00(t) + ts.fraction);
		out.attr("class") = CharacterVector::create("POSIXct", "POSIXt");
		out.attr("tzone") = "UTC";
		return out;
	}

	RObject fill_column(turbodbc::type_code code, size_t size, cpp_odbc::multi_value_buffer const & buffer) {
	{
		switch (code) {
			case type_code::boolean: {
				LogicalVector out = LogicalVector(size);
				for (std::size_t i = 0; i != size; ++i) {
					out[i] = *reinterpret_cast<bool const*>(buffer[i].data_pointer);
				}
				return(out);
															 }
			case type_code::integer: {
				IntegerVector out = IntegerVector(size);
				for (std::size_t i = 0; i != size; ++i) {
					out[i] = *reinterpret_cast<long const*>(buffer[i].data_pointer);
				}
				return(out);
															 }
			case type_code::floating_point: {
				NumericVector out = NumericVector(size);
				for (std::size_t i = 0; i != size; ++i) {
					out[i] = *reinterpret_cast<double const*>(buffer[i].data_pointer);
				}
				return(out);
																			}
			case type_code::string: {
				CharacterVector out = CharacterVector(size);
				for (std::size_t i = 0; i != size; ++i) {
					out[i] = reinterpret_cast<char const*>(buffer[i].data_pointer);
				}
				return(out);
		}
			case type_code::date:
				//return make_date(size);
			case type_code::timestamp:
				//return make_timestamp(size);
			default:
				throw std::logic_error("Encountered unsupported type code");
		}
	}

}
	RObject make_object(turbodbc::type_code code, char const * data_pointer)
	{
		switch (code) {
			case type_code::boolean:
				return LogicalVector(*reinterpret_cast<bool const *>(data_pointer));
			case type_code::integer:
				return IntegerVector(*reinterpret_cast<long const *>(data_pointer));
			case type_code::floating_point:
				return NumericVector(*reinterpret_cast<double const *>(data_pointer));
			case type_code::string:
				return CharacterVector(reinterpret_cast<char const *>(data_pointer));
			case type_code::date:
				return make_date(*reinterpret_cast<SQL_DATE_STRUCT const *>(data_pointer));
			case type_code::timestamp:
				return make_timestamp(*reinterpret_cast<SQL_TIMESTAMP_STRUCT const *>(data_pointer));
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


RObject r_result_set::fetch_row()
{
	//auto const row = base_result_.fetch_row();
	//if (not row.empty()) {
		//List r_row;
		//for (std::size_t column = 0; column != row.size(); ++column) {
			//if (row[column].indicator == SQL_NULL_DATA) {
				//r_row.push_back(R_NilValue);
			//} else {
				//r_row.push_back(make_object(types_[column], row[column].data_pointer));
			//}
		//}
		//return r_row;
	//} else {
		//return List();
	//}
}

RObject r_result_set::fetch_all()
{
	std::size_t rows_in_batch = base_result_.fetch_next_batch();
	Rcpp::Rcout << rows_in_batch << '\n';

	//do {
		//Rcpp::Rcout << rows_in_batch << '\n';
		//rows_in_batch = base_result_.fetch_next_batch();
	//} while (rows_in_batch != 0);
	//return Rcpp::List();

	auto const column_info = base_result_.get_column_info();
	auto const n_columns = column_info.size();

	List columns(n_columns);
	auto const buffers = base_result_.get_buffers();

	CharacterVector names(n_columns);
	for (std::size_t i = 0; i != n_columns; ++i) {
		columns[i] = fill_column(column_info[i].type, rows_in_batch, buffers[i]);
		names[i] = column_info[i].name;
	}

  columns.attr("names") = names;
  columns.attr("class") = CharacterVector::create("tbl_df", "tbl", "data.frame");
  columns.attr("row.names") = IntegerVector::create(NA_INTEGER, -(rows_in_batch));
	return columns;
}
} }

	//do {
		//auto const buffers = base_result_.get_buffers();

		//for (std::size_t i = 0; i != n_columns; ++i) {
			//columns[i] = make_object(column_info[i].type, buffers[i].get());
		//}
		//rows_in_batch = base_result_.fetch_next_batch();
	//} while (rows_in_batch != 0);

	//return as_python_list(columns);
//}


//} }
