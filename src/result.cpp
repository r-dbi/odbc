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
  //return c.get() != NULL;
  return TRUE;
}

// [[Rcpp::export]]
bool result_completed(result_ptr r) {
  //auto rs = c->get_result_set();
  //return !rs || rs->has_completed();
  return TRUE;
}

// [[Rcpp::export]]
result_ptr query(connection_ptr p, std::string sql, std::size_t size = 1024) {
  return result_ptr(new odbconnect::odbc_result(*p, sql));
}

// [[Rcpp::export]]
List result_fetch(result_ptr r, int n_max = -1) {
  return r->fetch(n_max);
}

// [[Rcpp::export]]
void column_info(result_ptr r) {
  //auto columns = c->get_result_set()->get_column_info();
  //for (auto info : columns) {
    //Rcpp::Rcout << info.name << ':' << (int) info.type << ':' << info.supports_null_values << '\n';
  //}
}

// [[Rcpp::export]]
void result_bind(result_ptr r, List params) {
  //c->add_parameter_set(params);
  //c->execute();
}

// [[Rcpp::export]]
void result_execute(result_ptr r) {
  r->execute();
}

// [[Rcpp::export]]
void result_insert_dataframe(result_ptr r, DataFrame df) {
  //c->add_parameter_set(df);
  //c->execute();
  //c.release();
}

// [[Rcpp::export]]
int result_rows_affected(result_ptr r) {
  auto res = r->result();
  return res ? res.affected_rows() : 0;
}

// [[Rcpp::export]]
int result_row_count(result_ptr r) {
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
