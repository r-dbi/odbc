#pragma once

#include <nanodbc.h>
#include <memory>
#include <Rcpp.h>
#include "r_types.h"
#include "odbc_connection.h"

namespace odbconnect {
typedef std::array<const char, 255> string_buf;

class odbc_result {
  public:
    odbc_result(odbc_connection & c, std::string sql) :
      c_(&c) ,
      sql_(sql),
      rows_fetched_(0),
      complete_(0) {
        s_ = std::make_shared<nanodbc::statement>(*c.connection(), sql);
      };
    std::shared_ptr<odbc_connection> connection() const {
      return std::shared_ptr<odbc_connection>(c_);
    }
    std::shared_ptr<nanodbc::statement> statement() const {
      return std::shared_ptr<nanodbc::statement>(s_);
    }
    std::shared_ptr<nanodbc::result> result() const {
      return std::shared_ptr<nanodbc::result>(r_);
    }
    void execute() {
      if (!r_) {
        r_ = std::make_shared<nanodbc::result>(s_->execute());
        c_->current_result(this);
      }
    }
    void insert_dataframe(Rcpp::DataFrame const & df) {
      auto types = column_types(df);
      auto ncols = df.size();
      auto nrows = df.nrows();
      int start = 0;
      int batch_size = 1024;
      nanodbc::transaction transaction(*c_->connection());

      while(start < nrows) {
        auto s = nanodbc::statement(*c_->connection(), sql_);
        size_t end = start + batch_size > nrows ? nrows : start + batch_size;
        size_t size = end - start;
        clear_buffers();

        for (short col = 0; col < ncols; ++col) {
          switch(types[col]) {
            case logical_t: bind_logical(s, df, col, start, size); break;
            case date_t: bind_date(s, df, col, start, size); break;
            case datetime_t: bind_datetime(s, df, col, start, size); break;
            case double_t: bind_double(s, df, col, start, size); break;
            case integer_t: bind_integer(s, df, col, start, size); break;
            case string_t: bind_string(s, df, col, start, size); break;
            case raw_t: bind_raw(s, df, col, start, size); break;
            default: Rcpp::stop("Not yet implemented (%s)!", types[col]); break;

          }
        }
        nanodbc::execute(s, size);
        start += batch_size;
      }
      transaction.commit();
    }
    Rcpp::List fetch(int n_max = -1) {
      execute();
      return result_to_dataframe(*r_, n_max);
    }

    int rows_fetched() {
      return rows_fetched_ == 0 ? 0 : rows_fetched_;
    }

    bool complete() {
      return
        r_->columns() == 0 || // query had no result
        complete_; // result is completed
    }

    bool active() {
      return c_->current_result() == this;
    }

    ~odbc_result() {
      c_->current_result(nullptr);
    }

  private:
    odbc_connection *c_;
    std::shared_ptr<nanodbc::statement> s_;
    std::shared_ptr<nanodbc::result> r_;
    std::string sql_;
    static const int seconds_in_day_ = 24 * 60 * 60;
    size_t rows_fetched_;
    bool complete_;

    std::map<short, std::vector<std::string>> strings_;
    std::map<short, std::vector<std::vector<uint8_t>>> raws_;
    std::map<short, std::vector<nanodbc::timestamp>> times_;
    std::map<short, std::vector<uint8_t>> nulls_;

    void clear_buffers() {
      strings_.clear();
      raws_.clear();
      times_.clear();
      nulls_.clear();
    }

    void bind_logical(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {
      nulls_[column] = std::vector<uint8_t>(size, false);
      auto vector = LOGICAL(data[column]);
      for (size_t i = 0;i < size;++i) {
        if (vector[start + i] == NA_LOGICAL) {
          nulls_[column][i] = true;
        }
      }
      auto t = reinterpret_cast<const int *>(&LOGICAL(data[column])[start]);
      statement.bind<int>(column, t, size, reinterpret_cast<bool *>(nulls_[column].data()));
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
    void bind_raw(nanodbc::statement & statement, Rcpp::DataFrame const & data, short column, size_t start, size_t size) {
      nulls_[column] = std::vector<uint8_t>(size, false);
      for (size_t i = 0;i < size;++i) {
        SEXP value = VECTOR_ELT(data[column], start + i);
        if (TYPEOF(value) == NILSXP) {
          nulls_[column][i] = true;
          raws_[column].push_back(std::vector<uint8_t>());
        } else {
          raws_[column].push_back(std::vector<uint8_t>(RAW(value), RAW(value) + Rf_length(value)));
        }
      }

      statement.bind(column, raws_[column], reinterpret_cast<bool *>(nulls_[column].data()));
    }

    nanodbc::timestamp as_timestamp(double value) {
      nanodbc::timestamp ts;
      auto frac = modf(value, &value);
      time_t t = static_cast<time_t>(value);
      auto tm = gmtime(&t);
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

    std::vector<std::string> column_names(nanodbc::result const & r) {
      std::vector<std::string> names;
      names.reserve(r.columns());
      for (short i = 0;i < r.columns();++i) {
        names.push_back(r.column_name(i));
      }
      return names;
    }

    double as_double(nanodbc::timestamp const & ts)
    {
      tm t;
      t.tm_sec = t.tm_min = t.tm_hour = t.tm_isdst = 0;

      t.tm_year = ts.year - 1900;
      t.tm_mon = ts.month - 1;
      t.tm_mday = ts.day;
      t.tm_hour = ts.hour;
      t.tm_min = ts.min;
      t.tm_sec = ts.sec;

      return Rcpp::mktime00(t) + ts.fract;
    }

    Rcpp::List create_dataframe(std::vector<r_type> types, std::vector<std::string> names, int n) {
      int num_cols = types.size();
      Rcpp::List out(num_cols);
      out.attr("names") = names;
      out.attr("class") = "data.frame";
      out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

      for (int j = 0; j < num_cols; ++j) {
        switch (types[j]) {
          case integer_t: out[j] = Rf_allocVector(INTSXP, n); break;
          case date_t:
          case datetime_t:
          case odbconnect::double_t: out[j] = Rf_allocVector(REALSXP, n); break;
          case string_t: out[j] = Rf_allocVector(STRSXP, n); break;
          case raw_t: out[j] = Rf_allocVector(VECSXP, n); break;
          case logical_t: out[j] = Rf_allocVector(LGLSXP, n); break;
        }
      }
      return out;
    }

    Rcpp::List resize_dataframe(Rcpp::List df, int n) {
      int p = df.size();

      Rcpp::List out(p);
      for (int j = 0; j < p; ++j) {
        out[j] = Rf_lengthgets(df[j], n);
      }

      out.attr("names") = df.attr("names");
      out.attr("class") = df.attr("class");
      out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

      return out;
    }

    void add_classes(Rcpp::List& df, const std::vector<r_type> & types) {
      df.attr("class") = Rcpp::CharacterVector::create("data.frame");
      for (int col = 0; col < df.size(); ++col) {
        Rcpp::RObject x = df[col];
        switch (types[col]) {
          case date_t:
            x.attr("class") = Rcpp::CharacterVector::create("Date");
            break;
          case datetime_t:
            x.attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
            break;
          case raw_t:
            x.attr("class") = Rcpp::CharacterVector::create("blob");
            break;
          default:
            break;
        }
      }
    }

    std::vector<r_type> column_types(Rcpp::DataFrame const & df) {
      std::vector<r_type> types;
      types.reserve(df.size());
      for (short i = 0;i < df.size();++i) {
        switch(TYPEOF(df[i])) {
          case LGLSXP: types.push_back(logical_t); break;
          case INTSXP: types.push_back(integer_t); break;
          case REALSXP: {
            Rcpp::RObject x = df[i];
            if (x.inherits("Date")) {
              types.push_back(date_t);
            } else if (x.inherits("POSIXct")) {
              types.push_back(datetime_t);
            } else {
              types.push_back(double_t);
            }
            break;
          }
          case STRSXP: types.push_back(string_t); break;
          case VECSXP:
          case RAWSXP: types.push_back(raw_t); break;
          default: Rcpp::stop("Unsupported column type %s", Rf_type2char(TYPEOF(df[i])));
        }
      }

      return types;
    }

    std::vector<r_type> column_types(nanodbc::result const & r) {
      std::vector<r_type> types;
      types.reserve(r.columns());
      for (short i = 0;i < r.columns();++i) {

        short type = r.column_datatype(i);
        switch (type)
        {
          case SQL_BIT:
            types.push_back(logical_t);
            break;
          case SQL_TINYINT:
          case SQL_SMALLINT:
          case SQL_INTEGER:
          case SQL_BIGINT:
            types.push_back(integer_t);
            break;
            // Double
          case SQL_DOUBLE:
          case SQL_FLOAT:
          case SQL_DECIMAL:
          case SQL_REAL:
          case SQL_NUMERIC:
            types.push_back(double_t);
            break;
            // Date
          case SQL_DATE:
          case SQL_TYPE_DATE:
            types.push_back(date_t);
            break;
            // Time
          case SQL_TIME:
          case SQL_TIMESTAMP:
          case SQL_TYPE_TIMESTAMP:
          case SQL_TYPE_TIME:
            types.push_back(datetime_t);
            break;
          case SQL_CHAR:
          case SQL_WCHAR:
          case SQL_VARCHAR:
          case SQL_WVARCHAR:
          case SQL_LONGVARCHAR:
          case SQL_WLONGVARCHAR:
            types.push_back(string_t);
            break;
          case SQL_BINARY:
          case SQL_VARBINARY:
          case SQL_LONGVARBINARY:
            types.push_back(raw_t);
            break;
          default:
            types.push_back(string_t);
            Rcpp::warning("Unknown field type (%s) in column %s", type, r.column_name(i));
            break;
        }
      }
      return types;
    }

    Rcpp::List result_to_dataframe(nanodbc::result & r, int n_max = -1) {

      auto types = column_types(r);

      int n = (n_max < 0) ? 100: n_max;

      Rcpp::List out = create_dataframe(types, column_names(r), n);
      int row = 0;

      if (rows_fetched_ == 0) {
        complete_ = !r.next();
      }

      while(!complete_) {
        if (row >= n) {
          if (n_max < 0) {
            n *= 2;
            out = resize_dataframe(out, n);
          } else {
            break;
          }
        }
        for (short col = 0;col < r.columns(); ++col) {
          switch(types[col]) {
            case date_t: assign_date(out, row, col, r); break;
            case datetime_t: assign_datetime(out, row, col, r); break;
            case odbconnect::double_t: assign_double(out, row, col, r); break;
            case integer_t: assign_integer(out, row, col, r); break;
            case string_t: assign_string(out, row, col, r); break;
            case logical_t: assign_logical(out, row, col, r); break;
            case raw_t: assign_raw(out, row, col, r); break;
            default:
                            Rcpp::warning("Unknown field type (%s) in column %s", types[col], r.column_name(col));
          }
        }

        complete_ = !r.next();
        ++row;
        ++rows_fetched_;
      }

      // Resize if needed
      if (row < n) {
        out = resize_dataframe(out, row);
      }

      add_classes(out, types);
      return out;
    }

    void assign_integer(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      INTEGER(out[column])[row] = value.get<int>(column, NA_INTEGER);
    }
    void assign_double(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      REAL(out[column])[row] = value.get<double>(column, NA_REAL);
    }
    void assign_string(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      SEXP res;

      if (value.is_null(column)) {
        res = NA_STRING;
      } else {
        // There is a bug/limitation in ODBC drivers for SQL Server (and possibly others)
        // which causes SQLBindCol() to never write SQL_NOT_NULL to the length/indicator
        // buffer unless you also bind the data column. nanodbc's is_null() will return
        // correct values for (n)varchar(max) columns when you ensure that SQLGetData()
        // has been called for that column (i.e. after get() or get_ref() is called).
        auto str = value.get<std::string>(column);
        if (value.is_null(column)) {
          res = NA_STRING;
        } else {
          res = Rf_mkCharCE(str.c_str(), CE_UTF8);
        }
      }
      SET_STRING_ELT(out[column], row, res);
    }

    void assign_datetime(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      double res;

      if (value.is_null(column)) {
        res = NA_REAL;
      } else {
        auto ts = value.get<nanodbc::timestamp>(column);
        res = as_double(ts);
      }

      REAL(out[column])[row] = res;
    }
    void assign_date(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      double res;

      if (value.is_null(column)) {
        res = NA_REAL;
      } else {
        auto ts = value.get<nanodbc::timestamp>(column);
        res = as_double(ts);
      }

      REAL(out[column])[row] = res / seconds_in_day_;
    }

    void assign_logical(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {
      LOGICAL(out[column])[row] = value.get<int>(column, NA_LOGICAL);
    }

    void assign_raw(Rcpp::List & out, size_t row, short column, nanodbc::result & value) {

      // Same issue as assign_string, null is never true unless the column has been bound
      std::vector<std::uint8_t> data = value.get<std::vector<std::uint8_t>>(column);
      if (value.is_null(column)) {
        SET_VECTOR_ELT(Rf_allocVector(VECSXP, 1), 0, NILSXP);
        return;
      }
      SEXP bytes = Rf_allocVector(RAWSXP, data.size());
      std::copy(data.begin(), data.end(), RAW(bytes));
      SET_VECTOR_ELT(out[column], row, bytes);
    }
};
}
