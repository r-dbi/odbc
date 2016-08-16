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
  return c.get() != NULL && !(*c)->is_active();
}

// [[Rcpp::export]]
bool result_completed(cursor_ptr c) {
  return (*c)->get_result_set()->has_completed();
}

// [[Rcpp::export]]
cursor_ptr query(connection_ptr p, std::string sql, std::size_t size = 1024) {

  auto c = boost::make_shared<turbodbc::cursor>(turbodbc::cursor((*p), size, 1024, false));
  c->prepare(sql);
  c->execute();

  return cursor_ptr(new boost::shared_ptr<turbodbc::cursor const>(c));
}

// [[Rcpp::export]]
List result_fetch(cursor_ptr c, int n = -1) {
  List out;
  if (n == -1) {
    out = (*c)->get_result_set()->fetch_all();
  } else {
    out = (*c)->get_result_set()->fetch(n);
  }
  if (as<List>(out).length() == 0) {
    stop("Result set is inactive");
  }
  return out;
}

// [[Rcpp::export]]
void column_info(cursor_ptr c) {
  auto columns = (*c)->get_result_set()->get_column_info();
  for (auto info : columns) {
    Rcpp::Rcout << info.name << ':' << (int) info.type << ':' << info.supports_null_values << '\n';
  }
}
