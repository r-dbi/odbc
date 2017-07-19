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
    std::string connection_string, std::string timezone, std::string encoding)
    : current_result_(nullptr),
      encoding_(encoding),
      bigint_mapping_(i64_to_integer64) {

  if (!cctz::load_time_zone(timezone, &timezone_)) {
    Rcpp::stop("Error loading time zone (%s)", timezone);
  }

  try {
    c_ = std::make_shared<nanodbc::connection>(connection_string);
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
  t_.release();
}
void odbc_connection::rollback() const {
  if (!t_) {
    Rcpp::stop("Rollback without beginning transaction");
  }
  t_->rollback();
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
std::string odbc_connection::encoding() const { return encoding_; }

bigint_map_t odbc_connection::get_bigint_mapping() const {
  return bigint_mapping_;
}

void odbc_connection::set_bigint_mapping(bigint_map_t map_to) {
  bigint_mapping_ = map_to;
}

} // namespace odbc
