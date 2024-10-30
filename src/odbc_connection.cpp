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
      output_encoder_(nullptr),
      column_name_encoder_(nullptr),
      interruptible_execution_(interruptible_execution) {

  output_encoder_ = std::make_shared<Iconv>(encoding, "UTF-8");
  column_name_encoder_ = std::make_shared<Iconv>(name_encoding, "UTF-8");
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
    c_ = std::make_shared<nanodbc::connection>(connection_string, attributes);
  } catch (const nanodbc::database_error& e) {
    utils::raise_error(odbc_error(e, "", *output_encoder_));
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
    std::string dbms = c_->get_info<std::string>(SQL_DBMS_NAME);
    std::string driver = c_->get_info<std::string>(SQL_DRIVER_NAME);
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
const std::shared_ptr<Iconv> odbc_connection::output_encoder() const { return output_encoder_; }
const std::shared_ptr<Iconv> odbc_connection::column_name_encoder() const { return column_name_encoder_; }

bigint_map_t odbc_connection::get_bigint_mapping() const {
  return bigint_mapping_;
}

} // namespace odbc
