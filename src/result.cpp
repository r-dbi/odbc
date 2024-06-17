#include "odbc_result.h"
#include "odbc_types.h"
#include "sql_types.h"

using namespace Rcpp;
using namespace nanodbc;

// [[Rcpp::export]]
void result_release(result_ptr r) { r.release(); }

// [[Rcpp::export]]
bool result_active(result_ptr const& r) {
  return r.get() != nullptr && r->active();
}

// [[Rcpp::export]]
bool result_completed(result_ptr const& r) { return r->complete(); }

// [[Rcpp::export]]
result_ptr new_result(
    connection_ptr const& p, std::string const& sql, const bool immediate) {
  return result_ptr(new odbc::odbc_result(*p, sql, immediate));
}

// [[Rcpp::export]]
List result_fetch(result_ptr const& r, const int n_max = -1) {
  return r->fetch(n_max);
}

// [[Rcpp::export]]
Rcpp::DataFrame result_column_info(result_ptr const& r) {
  auto result = r->result();

  std::vector<std::string> names;
  std::vector<std::string> field_type;
  for (short i = 0; i < result->columns(); ++i) {
    names.push_back(result->column_name(i));
    field_type.push_back(std::to_string(result->column_datatype(i)));
  }

  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names,
      Rcpp::_["type"] = field_type,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
void result_bind(result_ptr const& r, List const& params, size_t batch_rows) {
  r->bind_list(params, false, batch_rows);
}

// [[Rcpp::export]]
void result_insert_dataframe(
    result_ptr const& r, DataFrame const& df, size_t batch_rows) {
  r->bind_list(df, true, batch_rows);
}

// [[Rcpp::export]]
void result_describe_parameters(result_ptr const& r, DataFrame const& df) {
  r->describe_parameters(df);
}

// [[Rcpp::export]]
int result_rows_affected(result_ptr const& r) {
  auto res = r->result();
  if (!res) {
    return 0;
  }
  return res->affected_rows() > 0 ? res->affected_rows() : 0;
}

// [[Rcpp::export]]
int result_row_count(result_ptr const& r) { return r->rows_fetched(); }

// [[Rcpp::export]]
void column_types(DataFrame const& df) {
  for (int j = 0; j < df.size(); ++j) {
    Rcpp::Rcout << "type: " << Rf_type2char(TYPEOF(df[j])) << std::endl;
  }
}
