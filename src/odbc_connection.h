#pragma once

#include <nanodbc.h>

namespace odbconnect {
class odbc_connection {
  public:
    odbc_connection(std::string connection_string)
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

  private:
      std::shared_ptr<nanodbc::connection> c_;
      std::unique_ptr<nanodbc::transaction> t_;
};
}
