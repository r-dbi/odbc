#include "odbconnect_types.h"

// [[Rcpp::export]]
void result_release(cursor_ptr c) {
  c.release();
}

// [[Rcpp::export]]
bool result_active(cursor_ptr c) {
  return c.get() != NULL;
}
