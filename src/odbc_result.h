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
      size_t start = 0;
      size_t batch_size = 1024;
      nanodbc::transaction transaction(c_);

      while(start < nrows) {
        auto s = nanodbc::statement(c_, sql_);
        size_t end = start + batch_size > nrows ? nrows : start + batch_size;
        size_t size = end - start;
        std::map<short, std::vector<std::string>> str;
        std::map<short, std::vector<nanodbc::timestamp>> times;
        std::map<short, std::vector<uint8_t>> nulls;

        for (short col = 0; col < ncols; ++col) {
          switch(types[col]) {
            case integer_t: s.bind(col, &INTEGER(df[col])[start], size, &NA_INTEGER); break;
            case double_t: {
              // We cannot use a sentinel becuase NaN != NaN for
              // all values of NaN, even if the bits are the
              // same.
              nulls[col] = std::vector<uint8_t>(size, false);
              auto column = REAL(df[col]);

              size_t i = 0;
              for (size_t row = start; row < end; ++row, ++i) {
                if (ISNA(column[row])) {
                  nulls[col][i] = true;
                }
              }

              s.bind(col, &REAL(df[col])[start], size, reinterpret_cast<bool *>(nulls[col].data())); break;
            }
            case string_t: {
              nulls[col] = std::vector<uint8_t>(size, false);
              size_t i = 0;
              for (size_t row = start; row < end; ++row) {
                auto a = STRING_ELT(df[col], row);
                if (a == NA_STRING) {
                  nulls[col][i] = true;
                }
                str[col].push_back(Rf_translateCharUTF8(a));
                ++i;
              }
              s.bind_strings(col, str[col], reinterpret_cast<bool *>(nulls[col].data())); break;
            }
            case date_time_t: {
              nulls[col] = std::vector<uint8_t>(size, false);

              size_t i = 0;
              for (size_t row = start; row < end; ++row, ++i) {
                nanodbc::timestamp ts;
                auto d = REAL(df[col])[row];
                if (ISNA(d)) {
                  nulls[col][i] = true;
                } else {
                  auto frac = modf(d, &d);
                  time_t t = static_cast<time_t>(d);
                  auto tm = localtime(&t);
                  ts.fract = frac;
                  ts.sec = tm->tm_sec;
                  ts.min = tm->tm_min;
                  ts.hour = tm->tm_hour;
                  ts.day = tm->tm_mday;
                  ts.month = tm->tm_mon + 1;
                  ts.year = tm->tm_year + 1900;
                }
                times[col].push_back(ts);
              }
              s.bind(col, times[col].data(), size, reinterpret_cast<bool *>(nulls[col].data())); break;
            }
            default: Rcpp::stop("Not yet implemented!"); break;
          }
        }
        nanodbc::execute(s, size);
        start += batch_size;
      }
      transaction.commit();
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
