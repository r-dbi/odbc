#include "odbc_result.h"
#include "odbc_connection.h"

void odbconnect::odbc_connection::set_current_result(odbc_result *r) {
  if (r == current_result_) {
    return;
  }

  if (current_result_ != nullptr) {
    if (r != nullptr) {
      Rcpp::warning("Cancelling previous query");
      current_result_->statement()->cancel();
    }
  }

  current_result_ = r;
}
