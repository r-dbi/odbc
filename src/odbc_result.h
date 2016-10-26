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
        clear_buffers();

        for (short col = 0; col < ncols; ++col) {
          switch(types[col]) {
            case integer_t: bind_integer(s, df, col, start, size); break;
            case double_t: bind_double(s, df, col, start, size); break;
            case string_t: bind_string(s, df, col, start, size); break;
            case datetime_t: bind_datetime(s, df, col, start, size); break;
            case date_t: bind_date(s, df, col, start, size); break;
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
    static const int seconds_in_day_ = 24 * 60 * 60;

    std::map<short, std::vector<std::string>> strings_;
    std::map<short, std::vector<nanodbc::timestamp>> times_;
    std::map<short, std::vector<uint8_t>> nulls_;

    void clear_buffers() {
      strings_.clear();
      times_.clear();
      nulls_.clear();
    }

    void bind_integer(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {
      statement.bind(column, &INTEGER(data[column])[start], size, &NA_INTEGER);
    }

    // We cannot use a sentinel for doubles becuase NaN != NaN for all values
    // of NaN, even if the bits are the same.
    void bind_double(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {
      nulls_[column] = std::vector<uint8_t>(size, false);

      auto vector = REAL(data[column]);
      for (size_t i = 0;i < size;++i) {
        if (ISNA(vector[start + i])) {
          nulls_[column][i] = true;
        }
      }

      statement.bind(column, &vector[start], size, reinterpret_cast<bool *>(nulls_[column].data()));
    }

    void bind_string(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {
      nulls_[column] = std::vector<uint8_t>(size, false);
      for (size_t i = 0;i < size;++i) {
        auto value = STRING_ELT(data[column], start + i);
        if (value == NA_STRING) {
          nulls_[column][i] = true;
        }
        strings_[column].push_back(Rf_translateCharUTF8(value));
      }

      statement.bind_strings(column, strings_[column], reinterpret_cast<bool *>(nulls_[column].data()));
    }

    nanodbc::timestamp as_timestamp(double value) {
      nanodbc::timestamp ts;
      auto frac = modf(value, &value);
      time_t t = static_cast<time_t>(value);
      auto tm = localtime(&t);
      ts.fract = frac;
      ts.sec = tm->tm_sec;
      ts.min = tm->tm_min;
      ts.hour = tm->tm_hour;
      ts.day = tm->tm_mday;
      ts.month = tm->tm_mon + 1;
      ts.year = tm->tm_year + 1900;
      return ts;
    }

    void bind_datetime(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {

      nulls_[column] = std::vector<uint8_t>(size, false);

      for (size_t i = 0;i < size;++i) {
        nanodbc::timestamp ts;
        auto value = REAL(data[column])[start + i];
        if (ISNA(value)) {
          nulls_[column][i] = true;
        } else {
          ts = as_timestamp(value);
        }
        times_[column].push_back(ts);
      }
      statement.bind(column, times_[column].data(), size, reinterpret_cast<bool *>(nulls_[column].data()));
    }
    void bind_date(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {

      nulls_[column] = std::vector<uint8_t>(size, false);

      for (size_t i = 0;i < size;++i) {
        nanodbc::timestamp ts;
        auto value = REAL(data[column])[start + i] * seconds_in_day_;
        if (ISNA(value)) {
          nulls_[column][i] = true;
        } else {
          ts = as_timestamp(value);
        }
        times_[column].push_back(ts);
      }
      statement.bind(column, times_[column].data(), size, reinterpret_cast<bool *>(nulls_[column].data()));
    }
};
}
