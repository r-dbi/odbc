#pragma once

#include <nanodbc.h>
#include <memory>
#include <Rcpp.h>
#include "r_types.h"
#include "utils.h"

namespace odbconnect {

class odbc_result {
  public:
    odbc_result(nanodbc::connection & c, std::string sql) :
      c_(c) {
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
      for (short col = 0; col < ncols; ++col) {
        Rcpp::Rcout << col << ':' << types[col] << '\n';
        switch(types[col]) {
          case integer_t: s_.bind(col, INTEGER(df[col]), nrows, &NA_INTEGER); break;
          case double_t: {
            s_.bind<double>(col, REAL(df[col]), nrows, &NA_REAL); break;
          }
//                          string_t: s_.bind_strings(col, )
        }
      }
      nanodbc::transact(s_, nrows);
    }
    Rcpp::List fetch(int n_max = -1) {
      execute();
      return result_to_dataframe(r_, n_max);
    }

  private:
    nanodbc::connection c_;
    nanodbc::statement s_;
    nanodbc::result r_;


};
}
