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
        switch(types[col]) {
          case integer_t: s_.bind(col, INTEGER(df[col]), nrows, &NA_INTEGER); break;
          case double_t: s_.bind<double>(col, REAL(df[col]), nrows, &NA_REAL); break;
          case string_t: {
            std::vector<std::string> str;
            for (size_t row = 0; row < nrows; ++row) {
              str.push_back(Rf_translateCharUTF8(STRING_ELT(df[col], row)));
            }
            s_.bind_strings(col, str, nrows); break;
          }
          case date_time_t: {
            std::vector<nanodbc::timestamp> times;
            for (size_t row = 0; row < nrows; ++row) {
              auto d = REAL(df[col])[row];
              auto frac = modf(d, &d);
              time_t t = static_cast<time_t>(d);
              auto tm = localtime(&t);
              nanodbc::timestamp ts;
              ts.fract = frac;
              ts.sec = tm->tm_sec;
              ts.min = tm->tm_min;
              ts.hour = tm->tm_hour;
              ts.day = tm->tm_mday;
              ts.month = tm->tm_mon + 1;
              ts.year = tm->tm_year + 1900;
              times.push_back(ts);
            }
            s_.bind(col, times.data(), nrows); break;
          }
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
