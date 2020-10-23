#pragma once

#include <Rcpp.h>

#include "Iconv.h"
#include "condition.h"
#include "nanodbc.h"
#include "odbc_connection.h"
#include "r_types.h"

namespace odbc {

inline void signal_unknown_field_type(short type, const std::string& name) {
  char buf[100];
  sprintf(buf, "Unknown field type (%i) in column (%s)", type, name.c_str());
  signal_condition(buf, "odbc_unknown_field_type");
}

class odbc_error : public Rcpp::exception {
public:
  odbc_error(const nanodbc::database_error& e, const std::string& sql)
      : Rcpp::exception("", false) {
    message = std::string(e.what()) + "\n<SQL> '" + sql + "'";
  }
  const char* what() const NANODBC_NOEXCEPT { return message.c_str(); }

private:
  std::string message;
};

class odbc_result {
public:
  odbc_result(
      std::shared_ptr<odbc_connection> c, std::string sql, bool immediate);
  std::shared_ptr<odbc_connection> connection() const;
  std::shared_ptr<nanodbc::statement> statement() const;
  std::shared_ptr<nanodbc::result> result() const;
  void prepare();
  void execute();
  void describe_parameters(Rcpp::List const& x);
  void bind_list(Rcpp::List const& x, bool use_transaction, size_t batch_rows);
  Rcpp::DataFrame fetch(int n_max = -1);

  int rows_fetched();

  bool complete();

  bool active();

  ~odbc_result();

private:
  std::shared_ptr<odbc_connection> c_;
  std::shared_ptr<nanodbc::statement> s_;
  std::shared_ptr<nanodbc::result> r_;
  std::string sql_;
  static const int seconds_in_day_ = 24 * 60 * 60;
  static const int seconds_in_hour_ = 60 * 60;
  static const int seconds_in_minute_ = 60;
  size_t rows_fetched_;
  int num_columns_;
  bool complete_;
  bool bound_;
  Iconv output_encoder_;

  std::map<short, std::vector<std::string>> strings_;
  std::map<short, std::vector<std::vector<uint8_t>>> raws_;
  std::map<short, std::vector<nanodbc::time>> times_;
  std::map<short, std::vector<nanodbc::timestamp>> timestamps_;
  std::map<short, std::vector<nanodbc::date>> dates_;
  std::map<short, std::vector<uint8_t>> nulls_;

  void clear_buffers();
  void unbind_if_needed();

  void bind_columns(
      nanodbc::statement& statement,
      r_type type,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  void bind_logical(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  void bind_integer(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  // We cannot use a sentinel for doubles becuase NaN != NaN for all values
  // of NaN, even if the bits are the same.
  void bind_double(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  void bind_string(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);
  void bind_raw(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  nanodbc::timestamp as_timestamp(double value);

  nanodbc::date as_date(double value);

  nanodbc::time as_time(double value);

  void bind_datetime(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);
  void bind_date(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);

  void bind_time(
      nanodbc::statement& statement,
      Rcpp::List const& data,
      short column,
      size_t start,
      size_t size);
  std::vector<std::string> column_names(nanodbc::result const& r);

  double as_double(nanodbc::timestamp const& ts);

  double as_double(nanodbc::date const& dt);

  Rcpp::List create_dataframe(
      std::vector<r_type> types, std::vector<std::string> names, int n);

  Rcpp::List resize_dataframe(Rcpp::List df, int n);

  void add_classes(Rcpp::List& df, const std::vector<r_type>& types);

  std::vector<r_type> column_types(Rcpp::List const& list);

  std::vector<r_type> column_types(nanodbc::result const& r);

  Rcpp::List result_to_dataframe(nanodbc::result& r, int n_max = -1);

  void assign_integer(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);
  void assign_integer64(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);
  void assign_double(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);

  // Strings may be in the server's internal code page, so we need to re-encode
  // in UTF-8 if necessary.
  void assign_string(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);

  // unicode strings are converted to UTF-8 by nanodbc, so we just need to
  // mark the encoding.
  void assign_ustring(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);

  void assign_datetime(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);
  void assign_date(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);
  void assign_time(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);

  void assign_logical(
      Rcpp::List& out, size_t row, short column, nanodbc::result& value);

  void
  assign_raw(Rcpp::List& out, size_t row, short column, nanodbc::result& value);
};
} // namespace odbc
