#pragma once

#include "nanodbc.h"
#include <Rcpp.h>


namespace odbconnect {
class odbc_result;

class odbc_connection {
  public:
    odbc_connection(std::string connection_string) :
      current_result_(nullptr)
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
    bool has_active_result() const {
      return current_result_ != nullptr;
    }
    bool is_current_result(odbc_result* result) const {
      return current_result_ == result;
    }
    void set_current_result(odbc_result *r);

  private:
      std::shared_ptr<nanodbc::connection> c_;
      std::unique_ptr<nanodbc::transaction> t_;
      odbc_result* current_result_;
};

}
