#include "odbconnect_types.h"
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

using namespace Rcpp;

// [[Rcpp::export]]
void result_release(cursor_ptr c) {
  c.release();
}

// [[Rcpp::export]]
bool result_active(cursor_ptr c) {
  return c.get() != NULL && c->is_active();
}

// [[Rcpp::export]]
bool result_completed(cursor_ptr c) {
  auto rs = c->get_result_set();
  return !rs || rs->has_completed();
}

// [[Rcpp::export]]
cursor_ptr query(connection_ptr p, std::string sql, std::size_t size = 1024) {

  auto c = new turbodbc::cursor((*p), size, 1024, false);
  c->prepare(sql);
  c->execute();
  return cursor_ptr(c, true);
}

// [[Rcpp::export]]
List result_fetch(cursor_ptr c, int n = -1) {
  List out;
  auto rs = c->get_result_set();
  if (!rs) {
    out.attr("class") = "data.frame";
    return out;
  }
  if (n == -1) {
    out = rs->fetch_all();
  } else {
    out = rs->fetch(n);
  }
  if (as<List>(out).length() == 0) {
    stop("Result set is inactive");
  }
  return out;
}

// [[Rcpp::export]]
void column_info(cursor_ptr c) {
  auto columns = c->get_result_set()->get_column_info();
  for (auto info : columns) {
    Rcpp::Rcout << info.name << ':' << (int) info.type << ':' << info.supports_null_values << '\n';
  }
}

// [[Rcpp::export]]
void result_bind(cursor_ptr c, List params) {
  c->add_parameter_set(params);
  c->execute();
}

// [[Rcpp::export]]
void result_execute(cursor_ptr c) {
  c->execute();
}

// [[Rcpp::export]]
void result_insert_dataframe(cursor_ptr c, DataFrame df) {
  c->add_parameter_set(df);
  c->execute();
  c.release();
}

// [[Rcpp::export]]
void column_types(DataFrame df) {
  for (int j = 0;j < df.size(); ++j) {
    Rcpp::Rcout << "type: " << Rf_type2char(TYPEOF(df[j])) << std::endl;
  }
}
