#include "odbc_connection.h"
#include "odbc_result.h"

//odbconnect::odbc_connection::~odbc_connection() {
  ////if (r_ != nullptr) {
    ////r_->connection(nullptr);
  ////}
  //// delete r_ Do not delete odbc_result
//}
void odbconnect::odbc_connection::set_current_result(odbc_result *r) {
  if (r == current_result_) {
    return;
  }

  if (current_result_ != nullptr) {
    if (r != nullptr) {
      Rcpp::warning("Cancelling previous query");
      current_result_->statement()->cancel();
    }
    // TODO do we want to try and close the result here as well?
  }

  current_result_ = r;
}
