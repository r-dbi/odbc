#include <Rcpp.h>
#include "cpp_odbc/statement.h"
#include "odbconnect_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
statement_ptr statement_create(connection_ptr con, std::string sql) {
  auto statement = (*con)->make_statement();
  statement->prepare(sql);
  statement->execute_prepared();
  return statement_ptr(new std::shared_ptr<cpp_odbc::statement const>(statement), true);
}

// [[Rcpp::export]]
int row_count(statement_ptr rs) {
  return (*rs)->row_count();
}
