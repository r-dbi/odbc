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
  // both nano_error and sql must be UTF-8 encoded
  odbc_error(const std::string& nano_error, const std::string& sql)
	  : Rcpp::exception("", false) {
    std::string utf8_msg = nano_error + "\n<SQL> '" + sql + "'";
	  message = Rf_translateChar(Rf_mkCharCE(utf8_msg.c_str(), CE_UTF8));
  }
  const char* what() const NANODBC_NOEXCEPT { return message.c_str(); }

private:
  // #432: must be native encoded, as R expects native encoded chars for error msg
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
  Rcpp::StringVector column_names(nanodbc::result const& r);

  double as_double(nanodbc::timestamp const& ts);

  double as_double(nanodbc::date const& dt);

  Rcpp::List create_dataframe(
      std::vector<r_type> types, Rcpp::StringVector names, int n);

  Rcpp::List resize_dataframe(Rcpp::List df, int n);

  void add_classes(Rcpp::List& df, const std::vector<r_type>& types);

  std::vector<r_type> column_types(Rcpp::List const& list);

  std::vector<r_type> column_types(nanodbc::result const& r);

  Rcpp::List result_to_dataframe(nanodbc::result& r, int n_max = -1);

  /// \brief Safely gets data from the given column of the current rowset.
  ///
  /// There is a bug/limitation in ODBC drivers for SQL Server (and
  /// possibly others) which causes SQLBindCol() to never write
  /// SQL_NOT_NULL to the length/indicator buffer unless you also bind the
  /// data column. Since, any column can be unbound (think, for example
  /// columns coming after LONG data in the case of Microsoft's OEM
  /// ODBC driver) we also have to check for nullity after an attempt to
  /// nanodbc::get - this is when the null indicator gets set for unbound
  /// columns.  In the case when the null fallback is the same type
  /// as the data we are attempting to retrieve (int/NA_INTEGER,
  /// int64/NA_INTEGER64, double/NA_REAL, logical/NA_INTEGER), we can
  /// use the safe_get template below.  With others, for example
  /// std::string / NA_STRING, where the fallback is a SEXP, this
  /// check-for-nullity-after-get is coded directly in the assign_
  /// function.
  /// \param column short int position.
  /// \param fallback typename T value to use as fallback in case of null
  /// \param value nanodbc::result
  template <typename T>
  T safe_get(short column, T fallback, nanodbc::result& value);

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

  /**
   * @brief Convert the database-encoded string to UTF-8 encoding.
   *
   * There may be three different encodings: the encoding of the client (client-enc),
   * of the database (db-enc) and UTF-8 (for returned data.frame).
   *
   * More specifically, the statement (SQL) is encoded in client-enc and must be converted
   * to db-enc before it gets sent to the Database.
   *
   * The error message generated by nanodbc is encoded in db-enc as the message itself
   * is returned from the Database. However, before handled to R, the error message
   * needs to be converted to client-enc as R's messaging functions only accept
   * chars and could not do the encoding conversion for you.
   *
   * Finally, the results returned from the Database is encoded in db-enc, it may or may not
   * be the same as the UTF-8 or the client-enc (native encoding). odbc's solution is to
   * always convert the results to UTF-8 encoding. Not only UTF-8 in & out strategy is
   * one of a best practice, but also R only supports to mark the strings as latin1, UTF-8
   * or the native encoding. It means when db-enc is not one of three supported encodings,
   * the string becomes garbage letters in R.
   *
   * @note The term of "encoding of the database" (db-enc) may be unambiguous, due to the fact that
   *    ODBC drivers may provide options to translate character sets, making the issue even
   *    more complicate. In other words, there's actually an additional "encoding conversion layers"
   *    between the ODBC drivers and the Database server. Since `odbc` communicates with Database
   *    through the ODBC driver, the encoding of the database may refer to the encoding that's set
   *    by the driver (if any).
   *
   * @param str a `std::string` object encoded in the encoding of the database
   *            (specified by `odbc_connection::encoding`)
   * @return a `SEXP` object encoded in UTF-8
   */
  SEXP to_utf8(const std::string& str);
};
} // namespace odbc
