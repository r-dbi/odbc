#include "odbconnect_types.h"
#include "sqlext.h"
#include "utils.h"

using namespace Rcpp;
using namespace nanodbc;

// [[Rcpp::export]]
void result_release(result_ptr c) {
  c.release();
}

// [[Rcpp::export]]
bool result_active(result_ptr c) {
  //return c.get() != NULL;
  return TRUE;
}

// [[Rcpp::export]]
bool result_completed(result_ptr c) {
  //auto rs = c->get_result_set();
  //return !rs || rs->has_completed();
  return TRUE;
}

// [[Rcpp::export]]
result_ptr query(connection_ptr p, std::string sql, std::size_t size = 1024) {

  nanodbc::result* r = new nanodbc::result(nanodbc::execute(*p, sql));
  return result_ptr(r);
}

std::vector<std::string> column_names(nanodbc::result const & r) {
  std::vector<std::string> names;
  names.reserve(r.columns());
  for (short i = 0;i < r.columns();++i) {
    names.push_back(r.column_name(i));
  }
  return names;
}

double make_timestamp(nanodbc::timestamp const & ts)
{
  tm t;
  t.tm_sec = t.tm_min = t.tm_hour = t.tm_isdst = 0;

  t.tm_year = ts.year - 1900;
  t.tm_mon = ts.month - 1;
  t.tm_mday = ts.day;
  t.tm_hour = ts.hour;
  t.tm_min = ts.min;
  t.tm_sec = ts.sec;

  return Rcpp::mktime00(t) + ts.fract;
}

List result_set_to_data_frame(nanodbc::result & results, int n_max = -1) {
  auto types = column_types(results);

  int n = (n_max < 0) ? 100: n_max;

  List out = create_dataframe(types, column_names(results), n);
  int row = 0;
  for (auto &vals : results) {
    if (row >= n) {
      if (n_max < 0) {
        n *= 2;
        out = resize_dataframe(out, n);
      } else {
        break;
      }
    }
    for (short col = 0;col < results.columns(); ++col) {
      switch(types[col]) {
        case integer_t: INTEGER(out[col])[row] = vals.get<int>(col, NA_INTEGER); break;
        case date_t:
        case date_time_t: {
                        double val;
                         if (vals.is_null(col)) {
                           val = NA_REAL;
                         } else {
                        val = make_timestamp(vals.get<timestamp>(col));
                         }

                         REAL(out[col])[row] = val;
                         break;
                          }
        case odbconnect::double_t:
                        REAL(out[col])[row] = vals.get<double>(col, NA_REAL); break;
        case string_t: {
                         SEXP val;
                         if (vals.is_null(col)) {
                           val = NA_STRING;
                         } else {
                         val = Rf_mkCharCE(vals.get<string_type>(col).c_str(), CE_UTF8);
                         }
                         SET_STRING_ELT(out[col], row, val); break;
                       }
        //case raw_t: out[j] = Rf_allocVector(VECSXP, n); break;
        //case logical_t: out[j] = Rf_allocVector(LGLSXP, n); break;
      }
    }

    ++row;
  }
  if (row < n) {
    out = resize_dataframe(out, row);
  }
  return out;
}

// [[Rcpp::export]]
List result_fetch(result_ptr r, int n_max = -1) {
  return result_set_to_data_frame(*r, n_max);
}

// [[Rcpp::export]]
void column_info(result_ptr c) {
  //auto columns = c->get_result_set()->get_column_info();
  //for (auto info : columns) {
    //Rcpp::Rcout << info.name << ':' << (int) info.type << ':' << info.supports_null_values << '\n';
  //}
}

// [[Rcpp::export]]
void result_bind(result_ptr c, List params) {
  //c->add_parameter_set(params);
  //c->execute();
}

// [[Rcpp::export]]
void result_execute(result_ptr c) {
  //c->execute();
}

// [[Rcpp::export]]
void result_insert_dataframe(result_ptr c, DataFrame df) {
  //c->add_parameter_set(df);
  //c->execute();
  //c.release();
}

// [[Rcpp::export]]
int result_rows_affected(result_ptr c) {
  return c->rows();
  //return c->get_row_count();
}

// [[Rcpp::export]]
int result_row_count(result_ptr c) {
  //auto rs = c->get_result_set();
  //if (!rs) {
    //return 0;
  //}
  //return rs->get_rows_returned();
}

// [[Rcpp::export]]
void column_types(DataFrame df) {
  for (int j = 0;j < df.size(); ++j) {
    Rcpp::Rcout << "type: " << Rf_type2char(TYPEOF(df[j])) << std::endl;
  }
}
