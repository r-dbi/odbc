#include "odbc_connection.h"
#include "odbc_result.h"
#include "utils.h"

namespace odbc {

void odbc_connection::cancel_current_result() {
  if (current_result_ == nullptr) {
    return;
  }

  current_result_->statement()->cancel();
  current_result_ = nullptr;
}

bool odbc_connection::has_result() const {
  return current_result_ != nullptr;
}

void odbc_connection::set_current_result(odbc_result* r) {
  if (r == current_result_) {
    return;
  }

  cancel_current_result();
  current_result_ = r;
}

odbc_connection::odbc_connection(
    std::string const& connection_string,
    std::string const& timezone,
    std::string const& timezone_out,
    std::string const& encoding,
    std::string const& name_encoding,
    bigint_map_t const& bigint_mapping,
    long const& timeout,
    Rcpp::Nullable<Rcpp::List> const& r_attributes,
    bool const& interruptible_execution)
    : current_result_(nullptr),
      timezone_out_str_(timezone_out),
      bigint_mapping_(bigint_mapping),
      interruptible_execution_(interruptible_execution) {

  // `encoding` and `name_encoding` are accepted for backwards compatibility
  // but ignored: character data is always exchanged with the database via the
  // Unicode ("W") ODBC API and handed to R as UTF-8.
  (void)encoding;
  (void)name_encoding;
  if (!cctz::load_time_zone(timezone, &timezone_)) {
    Rcpp::stop("Error loading time zone (%s)", timezone);
  }

  // timezone_out_ will not be used. This line is just to ensure
  // the provided value is valid.
  if (!cctz::load_time_zone(timezone_out, &timezone_out_)) {
    Rcpp::stop("Error loading timezone_out (%s)", timezone_out);
  }

  try {
    std::list< nanodbc::connection::attribute > attributes;
    std::list< std::shared_ptr< void > > buffer_context;
    utils::prepare_connection_attributes(
        timeout, r_attributes, attributes, buffer_context );
    c_ = std::make_shared<nanodbc::connection>(
        utils::to_nanodbc_string(connection_string), attributes);
  } catch (const nanodbc::database_error& e) {
    utils::raise_error(odbc_error(e, ""));
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
  } catch (const nanodbc::database_error& e) {
    return false;
  }
}

bool odbc_connection::get_data_any_order() const {
  try {
    /* In a perfect world, we would use SQL_GETDATA_EXTENSIONS to
     * determine this.  However, some drivers incorrectly report these
     * extensions - for example FreeTDS supports out-of-order retrieval
     * via SQLGetData, but reports otherwise.  Therefore, at this time we
     * use empirical findings - we know this to be the case for the Microsoft
     * driver for SQL Server.
     */
    std::string dbms =
        utils::from_nanodbc_string(c_->get_info<nanodbc::string_type>(SQL_DBMS_NAME));
    std::string driver =
        utils::from_nanodbc_string(c_->get_info<nanodbc::string_type>(SQL_DRIVER_NAME));
    if (dbms == "Microsoft SQL Server" &&
		    driver.find("msodbcsql") != std::string::npos) {
      return false;
    }
    return true;
  } catch (const nanodbc::database_error& e) {
    return true;
  }
}

cctz::time_zone odbc_connection::timezone() const { return timezone_; }
std::string odbc_connection::timezone_out_str() const {
  return timezone_out_str_;
}

bigint_map_t odbc_connection::get_bigint_mapping() const {
  return bigint_mapping_;
}

} // namespace odbc
