#pragma once

#include <nanodbc.h>
#include <memory>
#include <Rcpp.h>
#include "r_types.h"
#include "utils.h"

namespace odbconnect {
typedef std::array<const char, 255> string_buf;

class odbc_result {
  public:
    odbc_result(nanodbc::connection & c, std::string sql) :
      c_(c),
      sql_(sql) {
        s_ = nanodbc::statement(c, sql);
      };
    nanodbc::connection connection() const {
      return c_;
    }
    nanodbc::statement statement() const {
      return s_;
    }
    nanodbc::result result() const {
      return r_;
    }
    void execute() {
      if (!r_) {
        r_ = s_.execute();
      }
    }
    void insert_dataframe(Rcpp::DataFrame const & df) {
      auto types = column_types(df);
      auto ncols = df.size();
      auto nrows = df.nrows();
      for (size_t row = 0; row < nrows; ++row) {
        s_ = nanodbc::statement(c_, sql_);
        for (short col = 0; col < ncols; ++col) {
          switch(types[col]) {
          case integer_t: s_.bind(col, INTEGER(df[col])); break;
          case double_t: s_.bind(col, REAL(df[col])); break;
          case string_t: {
            s_.bind(col, Rf_translateCharUTF8(STRING_ELT(df[col], row))); break;
          }
          }
        }
      nanodbc::execute(s_);
      }
    }
    Rcpp::List fetch(int n_max = -1) {
      execute();
      return result_to_dataframe(r_, n_max);
    }

  private:
    nanodbc::connection c_;
    nanodbc::statement s_;
    nanodbc::result r_;
    std::string sql_;
};
}
