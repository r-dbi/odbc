#include "odbconnect_types.h"
#include "sqlext.h"
#include "odbc_result.h"

using namespace Rcpp;
using namespace nanodbc;

// [[Rcpp::export]]
void result_release(result_ptr r) {
  r.release();
}

// [[Rcpp::export]]
bool result_active(result_ptr r) {
  return r.get() != nullptr && r->active();
}

// [[Rcpp::export]]
bool result_completed(result_ptr r) {
  return r->complete();
}

// [[Rcpp::export]]
result_ptr new_result(connection_ptr p, std::string sql, std::size_t size = 1024) {
  return result_ptr(new odbconnect::odbc_result(*p, sql));
}

// [[Rcpp::export]]
List result_fetch(result_ptr r, int n_max = -1) {
  return r->fetch(n_max);
}

// [[Rcpp::export]]
Rcpp::DataFrame result_column_info(result_ptr r) {
  auto result = r->result();

  std::vector<std::string> names;
  std::vector<std::string> field_type;
  for (short i = 0;i < result->columns();++i) {
    names.push_back(result->column_name(i));
    field_type.push_back(std::to_string(result->column_datatype(i)));
  }

  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names,
      Rcpp::_["type"] = field_type,
      Rcpp::_["stringsAsFactors"] = false
      );
}

// [[Rcpp::export]]
void result_bind(result_ptr r, List params) {
  r->insert_dataframe(params);
}

// [[Rcpp::export]]
void result_execute(result_ptr r) {
  r->execute();
}

// [[Rcpp::export]]
void result_insert_dataframe(result_ptr r, DataFrame df) {
  r->insert_dataframe(df);
}

// [[Rcpp::export]]
int result_rows_affected(result_ptr r) {
  auto res = r->result();
  return res ? res->affected_rows() : 0;
}

// [[Rcpp::export]]
int result_row_count(result_ptr r) {
  return r->rows_fetched();
}

// [[Rcpp::export]]
void column_types(DataFrame df) {
  for (int j = 0;j < df.size(); ++j) {
    Rcpp::Rcout << "type: " << Rf_type2char(TYPEOF(df[j])) << std::endl;
  }
}
