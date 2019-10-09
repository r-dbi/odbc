#include "odbc_connection.h"
#include "odbc_result.h"

namespace odbc {

void odbc_connection::set_current_result(odbc_result* r) {
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

odbc_connection::odbc_connection(
    std::string connection_string,
    std::string timezone,
    std::string timezone_out,
    std::string encoding,
    bigint_map_t bigint_mapping,
    long timeout)
    : current_result_(nullptr),
      timezone_out_str_(timezone_out),
      encoding_(encoding),
      bigint_mapping_(bigint_mapping) {

  if (!cctz::load_time_zone(timezone, &timezone_)) {
    Rcpp::stop("Error loading time zone (%s)", timezone);
  }

  if (!cctz::load_time_zone(timezone_out, &timezone_out_)) {
    Rcpp::stop("Error loading timezone_out (%s)", timezone_out);
  }

  try {
    c_ = std::make_shared<nanodbc::connection>(connection_string, timeout);
  } catch (nanodbc::database_error e) {
    throw Rcpp::exception(e.what(), FALSE);
  }
}

std::shared_ptr<nanodbc::connection> odbc_connection::connection() const {
  return std::shared_ptr<nanodbc::connection>(c_);
}

void odbc_connection::begin() {
  if (t_) {
    Rcpp::stop("Double begin");
  }
  t_ = std::unique_ptr<nanodbc::transaction>(new nanodbc::transaction(*c_));
}
void odbc_connection::commit() {
  if (!t_) {
    Rcpp::stop("Commit without beginning transaction");
  }
  t_->commit();
  t_.reset();
}
void odbc_connection::rollback() {
  if (!t_) {
    Rcpp::stop("Rollback without beginning transaction");
  }
  t_->rollback();
  t_.reset();
}
bool odbc_connection::has_active_result() const {
  return current_result_ != nullptr;
}
bool odbc_connection::is_current_result(odbc_result* result) const {
  return current_result_ == result;
}
bool odbc_connection::supports_transactions() const {
  try {
    return c_->get_info<unsigned short>(SQL_TXN_CAPABLE) != SQL_TC_NONE;
  } catch (nanodbc::database_error e) {
    return false;
  }
}

cctz::time_zone odbc_connection::timezone() const { return timezone_; }
std::string odbc_connection::timezone_out_str() const { return timezone_out_str_; }
std::string odbc_connection::encoding() const { return encoding_; }

bigint_map_t odbc_connection::get_bigint_mapping() const {
  return bigint_mapping_;
}

} // namespace odbc
