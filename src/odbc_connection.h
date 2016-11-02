#pragma once

#include <nanodbc.h>
#include <Rcpp.h>


namespace odbconnect {
class odbc_result;

class odbc_connection {
  public:
    odbc_connection(std::string connection_string) :
      r_(nullptr)
      {
        c_ = std::make_shared<nanodbc::connection>(connection_string);
      }

    std::shared_ptr<nanodbc::connection> connection() const {
      return std::shared_ptr<nanodbc::connection>(c_);
    }
    void begin() {
      t_ = std::unique_ptr<nanodbc::transaction>(new nanodbc::transaction(*c_));
    }
    void commit() const {
      t_->commit();
    }
    void rollback() const {
      t_->rollback();
    }
    void current_result(odbc_result *r) {
      if (r != nullptr && r_ != NULL) {
        Rcpp::warning("Cancelling previous query");

        // TODO do we want to try and close the result here as well?
      }

      r_ = r;
    }
    odbc_result* current_result() {
      return r_;
    }
    ~odbc_connection() {
      c_.reset();
      t_.release();
      // delete r_ Do not delete odbc_result
    }

  private:
      std::shared_ptr<nanodbc::connection> c_;
      std::unique_ptr<nanodbc::transaction> t_;
      odbc_result* r_;
};
}
