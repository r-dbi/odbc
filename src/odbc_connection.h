#pragma once

#include "nanodbc.h"
#include <Rcpp.h>
#include "time_zone.h"
#include <sqlext.h>

namespace odbc {
class odbc_result;

class odbc_connection {
  public:
    odbc_connection(std::string connection_string, std::string timezone = "UTC") :
      current_result_(nullptr)
      {

        if (!cctz::load_time_zone(timezone, &timezone_)) {
          Rcpp::stop("Error loading time zone (%s)", timezone);
        }

        c_ = std::make_shared<nanodbc::connection>(connection_string);
      }

    std::shared_ptr<nanodbc::connection> connection() const {
      return std::shared_ptr<nanodbc::connection>(c_);
    }

    void begin() {
      if (t_) {
        Rcpp::stop("Double begin");
      }
      t_ = std::unique_ptr<nanodbc::transaction>(new nanodbc::transaction(*c_));
    }
    void commit() const {
      if (!t_) {
        Rcpp::stop("Commit without beginning transaction");
      }
      t_->commit();
    }
    void rollback() const {
      if (!t_) {
        Rcpp::stop("Rollback without beginning transaction");
      }
      t_->rollback();
    }
    bool has_active_result() const {
      return current_result_ != nullptr;
    }
    bool is_current_result(odbc_result* result) const {
      return current_result_ == result;
    }
    bool supports_transactions() const {
      return c_->get_info<unsigned short>(SQL_TXN_CAPABLE) != SQL_TC_NONE;
    }

    void set_current_result(odbc_result *r);

    cctz::time_zone timezone() const {
      return timezone_;
    }

  private:
      std::shared_ptr<nanodbc::connection> c_;
      std::unique_ptr<nanodbc::transaction> t_;
      odbc_result* current_result_;
      cctz::time_zone timezone_;
};

}
