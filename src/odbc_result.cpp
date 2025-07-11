#include "odbc_result.h"
#include "integer64.h"
#include "time_zone.h"
#include "utils.h"
#include <chrono>
#include <memory>

#ifndef SQL_SS_TIME2
#define SQL_SS_TIME2 (-154)
#endif
#ifndef SQL_DB2_XML
#define SQL_DB2_XML (-370)
#endif
#ifndef SQL_SS_TIMESTAMPOFFSET
#define SQL_SS_TIMESTAMPOFFSET (-155)
#endif
namespace odbc {

using odbc::utils::run_interruptible;
using odbc::utils::raise_message;
using odbc::utils::raise_warning;
using odbc::utils::raise_error;
odbc_result::odbc_result(
    std::shared_ptr<odbc_connection> c, std::string sql, bool immediate)
    : c_(c),
      sql_(sql),
      rows_fetched_(0),
      num_columns_(0),
      complete_(0),
      bound_(false),
      immediate_(immediate),
      output_encoder_(c->output_encoder()),
      column_name_encoder_(c->column_name_encoder()) {

  c_->cancel_current_result();

  if (c_->interruptible_execution_) {
    auto exec_fn = std::mem_fn(&odbc_result::execute);
    auto cleanup_fn = [this]() {
      this->c_->set_current_result(nullptr);
      this->s_->close();
      this->s_.reset();
    };
    run_interruptible(std::bind(exec_fn, this), cleanup_fn);
  } else {
    this->execute();
  }
  return;
}

std::shared_ptr<odbc_connection> odbc_result::connection() const {
  return std::shared_ptr<odbc_connection>(c_);
}
std::shared_ptr<nanodbc::statement> odbc_result::statement() const {
  return std::shared_ptr<nanodbc::statement>(s_);
}
std::shared_ptr<nanodbc::result> odbc_result::result() const {
  return std::shared_ptr<nanodbc::result>(r_);
}

void odbc_result::execute() {
  try {
    c_->set_current_result(this);
    s_ = std::make_shared<nanodbc::statement>();
    if (!this->immediate_) s_->prepare(*c_->connection(), sql_);
    if (this->immediate_ || (s_->parameters() == 0)) {
      bound_ = true;
      r_ = std::make_shared<nanodbc::result>(
          this->immediate_ ? s_->execute_direct(*c_->connection(), sql_) :
          s_->execute());
      num_columns_ = r_->columns();
    }
  } catch (const nanodbc::database_error& e) {
    c_->set_current_result(nullptr);
    if (c_->interruptible_execution_) {
      // Executing in a thread away from main.  Signal
      // that we have encountered an error using an exception.
      // Main thread will raise the formatted [R] error.
      throw odbc_error(e, sql_, *output_encoder_);
    } else {
      // Executing on the main thread.  Raise the
      // formatted [R] errpr ourselves.
      raise_error(odbc_error(e, sql_, *output_encoder_));
    }
  } catch (...) {
    c_->set_current_result(nullptr);
    throw;
  }
}

void odbc_result::bind_columns(
    nanodbc::statement& statement,
    r_type type,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {

  switch (type) {
  case logical_t:
    bind_logical(*s_, data, column, start, size);
    break;
  case date_t:
    bind_date(*s_, data, column, start, size);
    break;
  case datetime_t:
    bind_datetime(*s_, data, column, start, size);
    break;
  case double_t:
    bind_double(*s_, data, column, start, size);
    break;
  case integer_t:
    bind_integer(*s_, data, column, start, size);
    break;
  case odbc::time_t:
    bind_time(*s_, data, column, start, size);
    break;
  case ustring_t:
  case string_t:
    bind_string(*s_, data, column, start, size);
    break;
  case raw_t:
    bind_raw(*s_, data, column, start, size);
    break;
  default:
    Rcpp::stop("Not yet implemented (%s)!", type);
    break;
  }
}

void odbc_result::describe_parameters(Rcpp::List const& x) {
  auto ncols = x.size();
  auto nrows = Rf_length(x[0]);

  if (nrows > s_->parameters()) {
    Rcpp::stop(
        "Query requires '%i' params; '%i' supplied.", s_->parameters(), ncols);
  }
  Rcpp::NumericVector idx = x["param_index"];
  Rcpp::NumericVector type = x["data_type"];
  Rcpp::NumericVector size = x["column_size"];
  Rcpp::NumericVector scale = x["decimal_digits"];

  idx = idx - 1L;
  s_->describe_parameters(
      Rcpp::as<std::vector<short>>(idx),
      Rcpp::as<std::vector<short>>(type),
      Rcpp::as<std::vector<unsigned long>>(size),
      Rcpp::as<std::vector<short>>(scale));
}

void odbc_result::bind_list(
    Rcpp::List const& x, bool use_transaction, size_t batch_rows) {
  complete_ = false;
  rows_fetched_ = 0;
  auto types = column_types(x);
  auto ncols = x.size();

  if (s_->parameters() == 0) {
    Rcpp::stop("Query does not require parameters.");
  }

  if (ncols != s_->parameters()) {
    Rcpp::stop(
        "Query requires '%i' params; '%i' supplied.", s_->parameters(), ncols);
  }
  size_t nrows = Rf_length(x[0]);
  size_t start = 0;
  std::unique_ptr<nanodbc::transaction> t;
  if (use_transaction && c_->supports_transactions()) {
    t = std::unique_ptr<nanodbc::transaction>(
        new nanodbc::transaction(*c_->connection()));
  }

  while (start < nrows) {
    size_t end = start + batch_rows > nrows ? nrows : start + batch_rows;
    size_t size = end - start;
    clear_buffers();

    for (short col = 0; col < ncols; ++col) {
      bind_columns(*s_, types[col], x, col, start, size);
    }
    r_ = std::make_shared<nanodbc::result>(nanodbc::execute(*s_, size));
    num_columns_ = r_->columns();
    start += batch_rows;

    Rcpp::checkUserInterrupt();
  }
  if (t) {
    t->commit();
  }
  bound_ = true;
}

Rcpp::DataFrame odbc_result::fetch(int n_max) {
  if (!bound_) {
    Rcpp::stop("Query needs to be bound before fetching");
  }
  if (num_columns_ == 0) {
    return Rcpp::DataFrame();
  }
  unbind_if_needed();
  try {
    return result_to_dataframe(*r_, n_max);
  } catch (...) {
    c_->set_current_result(nullptr);
    throw;
  }
}

void odbc_result::unbind_if_needed() {
  bool found_unbound = false;

  if (c_->get_data_any_order())
    return;
  try {
    for (short i = 0; i < num_columns_; ++i) {
      found_unbound = found_unbound || !r_->is_bound(i);
      if (found_unbound) {
        r_->unbind(i);
      }
    }
  } catch (const nanodbc::database_error& e) {
    raise_warning("Was unable to unbind some nanodbc buffers");
  };
}

int odbc_result::rows_fetched() {
  return rows_fetched_ == 0 ? 0 : rows_fetched_;
}

bool odbc_result::complete() {
  return num_columns_ == 0 || // query had no result
         complete_;           // result is completed
}

bool odbc_result::active() { return c_->is_current_result(this); }

odbc_result::~odbc_result() {
  if (c_ != nullptr && active()) {
    try {
      c_->set_current_result(nullptr);
    } catch (...) {
      // SQLCancel may throw an error.
      // Regardless, as this object is
      // getting destroyed, we need to
      // make sure the connection is not
      // holding onto an invalid reference
      c_->current_result_ = nullptr;
    };
  }
}

void odbc_result::clear_buffers() {
  strings_.clear();
  raws_.clear();
  times_.clear();
  timestamps_.clear();
  dates_.clear();
  nulls_.clear();
}

void odbc_result::bind_logical(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {
  nulls_[column] = std::vector<uint8_t>(size, false);
  auto vector = LOGICAL(data[column]);
  for (size_t i = 0; i < size; ++i) {
    if (vector[start + i] == NA_LOGICAL) {
      nulls_[column][i] = true;
    }
  }
  auto t = reinterpret_cast<const int*>(&LOGICAL(data[column])[start]);
  statement.bind<int>(
      column, t, size, reinterpret_cast<bool*>(nulls_[column].data()));
}

void odbc_result::bind_integer(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {
  nulls_[column] = std::vector<uint8_t>(size, false);

  auto vector = INTEGER(data[column]);
  for (size_t i = 0; i < size; ++i) {
    if (vector[start + i] == NA_INTEGER) {
      nulls_[column][i] = true;
    }
  }
  statement.bind(
      column,
      &INTEGER(data[column])[start],
      size,
      reinterpret_cast<bool*>(nulls_[column].data()));
}

// We cannot use a sentinel for doubles becuase NaN != NaN for all values
// of NaN, even if the bits are the same.
void odbc_result::bind_double(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {
  nulls_[column] = std::vector<uint8_t>(size, false);

  auto vector = REAL(data[column]);
  for (size_t i = 0; i < size; ++i) {
    if (ISNA(vector[start + i])) {
      nulls_[column][i] = true;
    }
  }

  statement.bind(
      column,
      &vector[start],
      size,
      reinterpret_cast<bool*>(nulls_[column].data()));
}

void odbc_result::bind_string(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {
  nulls_[column] = std::vector<uint8_t>(size, false);
  for (size_t i = 0; i < size; ++i) {
    auto value = STRING_ELT(data[column], start + i);
    if (value == NA_STRING) {
      nulls_[column][i] = true;
    }
    const char* v = CHAR(value);
    strings_[column].push_back(v);
  }

  statement.bind_strings(
      column, strings_[column], reinterpret_cast<bool*>(nulls_[column].data()));
}
void odbc_result::bind_raw(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {
  nulls_[column] = std::vector<uint8_t>(size, false);
  for (size_t i = 0; i < size; ++i) {
    SEXP value = VECTOR_ELT(data[column], start + i);
    if (TYPEOF(value) == NILSXP) {
      nulls_[column][i] = true;
      raws_[column].push_back(std::vector<uint8_t>());
    } else {
      raws_[column].push_back(
          std::vector<uint8_t>(RAW(value), RAW(value) + Rf_length(value)));
    }
  }

  statement.bind(
      column, raws_[column], reinterpret_cast<bool*>(nulls_[column].data()));
}

nanodbc::timestamp odbc_result::as_timestamp(double value, unsigned long long factor, unsigned long long pad) {
  nanodbc::timestamp ts;
  auto frac = modf(value, &value);

  using namespace std::chrono;
  auto utc_time = system_clock::from_time_t(static_cast<std::time_t>(value));

  auto civil_time = cctz::convert(utc_time, c_->timezone());
  ts.fract = (std::int32_t)(frac * factor) * pad;

  ts.sec = civil_time.second();
  ts.min = civil_time.minute();
  ts.hour = civil_time.hour();
  ts.day = civil_time.day();
  ts.month = civil_time.month();
  ts.year = civil_time.year();
  return ts;
}

nanodbc::date odbc_result::as_date(double value) {
  nanodbc::date dt;

  using namespace std::chrono;
  auto utc_time = system_clock::from_time_t(static_cast<std::time_t>(value));

  auto civil_time = cctz::convert(utc_time, cctz::utc_time_zone());
  dt.day = civil_time.day();
  dt.month = civil_time.month();
  dt.year = civil_time.year();
  return dt;
}

nanodbc::time odbc_result::as_time(double value) {
  nanodbc::time ts;
  ts.hour = value / seconds_in_hour_;
  auto remainder = static_cast<int>(value) % seconds_in_hour_;
  ts.min = remainder / seconds_in_minute_;
  ts.sec = remainder % seconds_in_minute_;
  return ts;
}

void odbc_result::bind_datetime(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {

  nulls_[column] = std::vector<uint8_t>(size, false);
  auto d = REAL(data[column]);

  nanodbc::timestamp ts;
  short precision = 3;
  try {
    precision = statement.parameter_scale(column);
  } catch (const nanodbc::database_error& e) {
    raise_warning("Unable to discern datetime precision. Using default (3).");
  };
  // Sanity scrub
  precision = std::min<short>(precision, 7);
  unsigned long long prec_adj = std::pow(10, precision);
  // The fraction field is expressed in billionths of
  // a second.
  unsigned long long pad = std::pow(10, 9 - precision);
  for (size_t i = 0; i < size; ++i) {
    auto value = d[start + i];
    if (ISNA(value)) {
      nulls_[column][i] = true;
    } else {
      ts = as_timestamp(value, prec_adj, pad);
    }
    timestamps_[column].push_back(ts);
  }
  statement.bind(
      column,
      timestamps_[column].data(),
      size,
      reinterpret_cast<bool*>(nulls_[column].data()));
}
void odbc_result::bind_date(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {

  nulls_[column] = std::vector<uint8_t>(size, false);
  auto d = REAL(data[column]);

  nanodbc::date dt;
  for (size_t i = 0; i < size; ++i) {
    auto value = d[start + i] * seconds_in_day_;
    if (ISNA(value)) {
      nulls_[column][i] = true;
    } else {
      dt = as_date(value);
    }
    dates_[column].push_back(dt);
  }
  statement.bind(
      column,
      dates_[column].data(),
      size,
      reinterpret_cast<bool*>(nulls_[column].data()));
}

void odbc_result::bind_time(
    nanodbc::statement& statement,
    Rcpp::List const& data,
    short column,
    size_t start,
    size_t size) {

  nulls_[column] = std::vector<uint8_t>(size, false);
  auto d = REAL(data[column]);

  nanodbc::time ts;
  for (size_t i = 0; i < size; ++i) {
    auto value = d[start + i];
    if (ISNA(value)) {
      nulls_[column][i] = true;
    } else {
      ts = as_time(value);
    }
    times_[column].push_back(ts);
  }
  statement.bind(
      column,
      times_[column].data(),
      size,
      reinterpret_cast<bool*>(nulls_[column].data()));
}
std::vector<std::string> odbc_result::column_names(nanodbc::result const& r) {
  std::vector<std::string> names;
  names.reserve(num_columns_);
  for (short i = 0; i < num_columns_; ++i) {
    nanodbc::string_type name = r.column_name(i);
    // Similar to the handling of string fields,
    // convert to UTF-8 before returning to user ( if needed )
    names.push_back(
        column_name_encoder_->makeString(name.c_str(), name.c_str() + name.length())
    );
  }
  return names;
}

double odbc_result::as_double(nanodbc::timestampoffset const& tso) {
  using namespace cctz;
  if (tso.offset_hour == 0 && tso.offset_minute == 0) {
    return as_double(tso.stamp);
  }
  const sys_seconds offset(tso.offset_hour * 3600 + tso.offset_minute * 60);

  // Make sure we can load timezone
  // Capture any error that we can raise
  // to [R] more gracefully.
  //
  // Note, when the TZ file can't be located on the FS,
  // `fixed_time_zone` will return false (and fallback to utc).
  // As we want to throw this warning ONCE, and not on *every*
  // failed row value, we test to see whether `cctz` has thrown
  // an error.  There, an error is thrown only *once* for each
  // (failed) time-zone.
  std::stringstream stream;
  std::streambuf* oldClogStreamBuf = std::clog.rdbuf(stream.rdbuf());
  cctz::time_zone tz = fixed_time_zone(offset);
  std::clog.rdbuf(oldClogStreamBuf);
  if (stream.rdbuf()->in_avail()) {
    std::stringstream msg;
    msg << "Unable to locate TZ corresponding to offset of " << offset.count() << " seconds.\n";
    msg << "Falling back to the `timezone` connection argument if specified, or `UTC` if not.";
    raise_warning(msg.str());
    return as_double(tso.stamp);
  }

  // sec is time_point
  auto sec = convert(
      civil_second(tso.stamp.year, tso.stamp.month, tso.stamp.day, tso.stamp.hour, tso.stamp.min, tso.stamp.sec),
      tz);
  return sec.time_since_epoch().count() + (tso.stamp.fract / 1000000000.0);
}

double odbc_result::as_double(nanodbc::timestamp const& ts) {
  using namespace cctz;
  auto sec = convert(
      civil_second(ts.year, ts.month, ts.day, ts.hour, ts.min, ts.sec),
      c_->timezone());
  return sec.time_since_epoch().count() + (ts.fract / 1000000000.0);
}

double odbc_result::as_double(nanodbc::date const& dt) {
  using namespace cctz;
  auto sec =
      convert(civil_day(dt.year, dt.month, dt.day), cctz::utc_time_zone());
  return sec.time_since_epoch().count();
}

Rcpp::List odbc_result::create_dataframe(
    std::vector<r_type> types, std::vector<std::string> names, int n) {
  int num_cols = types.size();
  Rcpp::List out(num_cols);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  for (int j = 0; j < num_cols; ++j) {
    switch (types[j]) {
    case integer_t:
      out[j] = Rf_allocVector(INTSXP, n);
      break;
    case integer64_t:
    case date_t:
    case datetime_t:
    case odbc::time_t:
    case odbc::double_t:
      out[j] = Rf_allocVector(REALSXP, n);
      break;
    case ustring_t:
    case string_t:
      out[j] = Rf_allocVector(STRSXP, n);
      break;
    case raw_t:
      out[j] = Rf_allocVector(VECSXP, n);
      break;
    case logical_t:
      out[j] = Rf_allocVector(LGLSXP, n);
      break;
    }
  }
  return out;
}

Rcpp::List odbc_result::resize_dataframe(Rcpp::List df, int n) {
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

void odbc_result::add_classes(
    Rcpp::List& df, const std::vector<r_type>& types) {
  df.attr("class") = Rcpp::CharacterVector::create("data.frame");
  for (int col = 0; col < df.size(); ++col) {
    Rcpp::RObject x = df[col];
    switch (types[col]) {
    case integer64_t:
      x.attr("class") = Rcpp::CharacterVector::create("integer64");
      break;
    case date_t:
      x.attr("class") = Rcpp::CharacterVector::create("Date");
      break;
    case datetime_t:
      x.attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
      x.attr("tzone") = Rcpp::CharacterVector::create(c_->timezone_out_str());
      break;
    case odbc::time_t:
      x.attr("class") = Rcpp::CharacterVector::create("hms", "difftime");
      x.attr("units") = Rcpp::CharacterVector::create("secs");
      break;
    case raw_t:
      // FIXME: Use new_blob()
      x.attr("ptype") = Rcpp::RawVector::create();
      x.attr("class") = Rcpp::CharacterVector::create(
          "blob", "vctrs_list_of", "vctrs_vctr", "list");
      break;
    default:
      break;
    }
  }
}

std::vector<r_type> odbc_result::column_types(Rcpp::List const& list) {
  std::vector<r_type> types;
  types.reserve(list.size());
  for (short i = 0; i < list.size(); ++i) {
    switch (TYPEOF(list[i])) {
    case LGLSXP:
      types.push_back(logical_t);
      break;
    case INTSXP:
      types.push_back(integer_t);
      break;
    case REALSXP: {
      Rcpp::RObject x = list[i];
      if (x.inherits("Date")) {
        types.push_back(date_t);
      } else if (x.inherits("POSIXct")) {
        types.push_back(datetime_t);
      } else if (x.inherits("difftime")) {
        types.push_back(odbc::time_t);
      } else {
        types.push_back(double_t);
      }
      break;
    }
    case STRSXP:
      types.push_back(string_t);
      break;
    case VECSXP:
    case RAWSXP:
      types.push_back(raw_t);
      break;
    default:
      Rcpp::stop("Unsupported column type %s", Rf_type2char(TYPEOF(list[i])));
    }
  }

  return types;
}

std::vector<r_type> odbc_result::column_types(nanodbc::result const& r) {
  std::vector<r_type> types;
  types.reserve(num_columns_);
  for (short i = 0; i < num_columns_; ++i) {

    short type = r.column_datatype(i);

    switch (type) {
    case SQL_BIT:
      types.push_back(logical_t);
      break;
    case SQL_TINYINT:
    case SQL_SMALLINT:
    case SQL_INTEGER:
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

    // 64 Bit Double
    case SQL_BIGINT:
      switch (connection()->get_bigint_mapping()) {
      case i64_to_integer:
        types.push_back(integer_t);
        break;
      case i64_to_double:
        types.push_back(double_t);
        break;
      case i64_to_character:
        types.push_back(string_t);
        break;
      case i64_to_integer64:
        types.push_back(integer64_t);
        break;
      default:
        types.push_back(string_t);
        signal_unknown_field_type(type, r.column_name(i));
        break;
      }
      break;

    // Date
    case SQL_DATE:
    case SQL_TYPE_DATE:
      types.push_back(date_t);
      break;
    // Time
    case SQL_TIME:
    case SQL_SS_TIME2:
    case SQL_TYPE_TIME:
      types.push_back(odbc::time_t);
      break;
    case SQL_TIMESTAMP:
    case SQL_TYPE_TIMESTAMP:
    case SQL_SS_TIMESTAMPOFFSET:
      types.push_back(datetime_t);
      break;
    case SQL_CHAR:
    case SQL_VARCHAR:
    case SQL_LONGVARCHAR:
      types.push_back(string_t);
      break;
    case SQL_WCHAR:
    case SQL_WVARCHAR:
    case SQL_WLONGVARCHAR:
      types.push_back(ustring_t);
      break;
    case SQL_BINARY:
    case SQL_VARBINARY:
    case SQL_LONGVARBINARY:
    case SQL_DB2_XML:
      types.push_back(raw_t);
      break;
    default:
      types.push_back(string_t);
      signal_unknown_field_type(type, r.column_name(i));
      break;
    }
  }
  return types;
}

bool odbc_result::nextResultSet(nanodbc::result& r) {
  while (r.next_result()) {
    // MYSQL, when returning from a CALL [proc]
    // returns a final result set containing a
    // status flag.  Protect against trying to
    // process/fetch this result set by checking
    // the number of columns.  This is
    // consistent with
    // https://dev.mysql.com/doc/c-api/8.0/en/c-api-prepared-call-statements.html
    if (r.columns() && r.next()) {
      return true;
    }
  };
  return false;
}

Rcpp::List odbc_result::result_to_dataframe(nanodbc::result& r, int n_max) {

  auto types = column_types(r);

  int n = (n_max < 0) ? 100 : n_max;

  Rcpp::List out = create_dataframe(types, column_names(r), n);
  int row = 0;

  if (rows_fetched_ == 0 && n > 0) {
    complete_ = !r.next() && !nextResultSet(r);
  }

  while (!complete_) {
    if (row >= n) {
      if (n_max < 0) {
        n *= 2;
        out = resize_dataframe(out, n);
      } else {
        break;
      }
    }
    for (size_t col = 0; col < types.size(); ++col) {
      switch (types[col]) {
      case date_t:
        assign_date(out, row, col, r);
        break;
      case datetime_t:
        assign_datetime(out, row, col, r);
        break;
      case odbc::double_t:
        assign_double(out, row, col, r);
        break;
      case integer_t:
        assign_integer(out, row, col, r);
        break;
      case integer64_t:
        assign_integer64(out, row, col, r);
        break;
      case odbc::time_t:
        assign_time(out, row, col, r);
        break;
      case string_t:
        assign_string(out, row, col, r);
        break;
      case ustring_t:
        assign_ustring(out, row, col, r);
        break;
      case logical_t:
        assign_logical(out, row, col, r);
        break;
      case raw_t:
        assign_raw(out, row, col, r);
        break;
      default:
        signal_unknown_field_type(types[col], r.column_name(col));
        break;
      } // switch (types[col])
    } // for (size_t col = 0,... )

    complete_ = !r.next();
    ++row;
    ++rows_fetched_;
    if (rows_fetched_ % 16384 == 0) {
      Rcpp::checkUserInterrupt();
    }
    complete_ = complete_ && !nextResultSet(r);
  } // while ( !complete_ )

  // Resize if needed
  if (row < n) {
    out = resize_dataframe(out, row);
  }

  add_classes(out, types);
  return out;
}

template <typename T>
T odbc_result::safe_get(short column, T fallback, nanodbc::result& value) {
  T res;
  res = value.get<T>(column, fallback);
  if (value.is_null(column)) {
    res = fallback;
  }
  return res;
}

void odbc_result::assign_integer(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {

  int res = safe_get<int>(column, NA_INTEGER, value);
  INTEGER(out[column])[row] = res;
}
void odbc_result::assign_integer64(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {

  int64_t res = safe_get<int64_t>(column, NA_INTEGER64, value);
  INTEGER64(out[column])[row] = res;
}
void odbc_result::assign_double(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {

  double res = safe_get<double>(column, NA_REAL, value);
  REAL(out[column])[row] = res;
}

void odbc_result::assign_logical(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {

  int res = safe_get<int>(column, NA_LOGICAL, value);
  LOGICAL(out[column])[row] = res;
}


// Strings may be in the server's internal code page, so we need to re-encode
// in UTF-8 if necessary.
void odbc_result::assign_string(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {
  SEXP res;

  if (value.is_null(column)) {
    res = NA_STRING;
  } else {
    auto str = value.get<std::string>(column);
    if (value.is_null(column)) {
      res = NA_STRING;
    } else {
      res = output_encoder_->makeSEXP(str.c_str(), str.c_str() + str.length());
    }
  }
  SET_STRING_ELT(out[column], row, res);
}

// unicode strings are converted to UTF-8 by nanodbc, so we just need to
// mark the encoding.
void odbc_result::assign_ustring(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {
  SEXP res;

  if (value.is_null(column)) {
    res = NA_STRING;
  } else {
    auto str = value.get<std::string>(column);
    if (value.is_null(column)) {
      res = NA_STRING;
    } else {
      res = Rf_mkCharCE(str.c_str(), CE_UTF8);
    }
  }
  SET_STRING_ELT(out[column], row, res);
}

void odbc_result::assign_datetime(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {
  double res;

  if (value.is_null(column)) {
    res = NA_REAL;
  } else {
    auto ts = value.get<nanodbc::timestampoffset>(column);
    if (value.is_null(column)) {
      res = NA_REAL;
    } else {
      res = as_double(ts);
    }
  }

  REAL(out[column])[row] = res;
}
void odbc_result::assign_date(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {
  double res;

  if (value.is_null(column)) {
    res = NA_REAL;
  } else {
    auto ts = value.get<nanodbc::date>(column);
    if (value.is_null(column)) {
      res = NA_REAL;
    } else {
      res = as_double(ts);
    }
  }

  REAL(out[column])[row] = res / seconds_in_day_;
}
void odbc_result::assign_time(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {
  double res;

  if (value.is_null(column)) {
    res = NA_REAL;
  } else {
    auto ts = value.get<nanodbc::time>(column);
    if (value.is_null(column)) {
      res = NA_REAL;
    } else {
      res = ts.hour * 3600 + ts.min * 60 + ts.sec;
    }
  }

  REAL(out[column])[row] = res;
}

void odbc_result::assign_raw(
    Rcpp::List& out, size_t row, short column, nanodbc::result& value) {

  // Same issue as assign_string, null is never true unless the column has
  // been bound
  if (value.is_null(column)) {
    SET_VECTOR_ELT(Rf_allocVector(VECSXP, 1), 0, NILSXP);
    return;
  }
  std::vector<std::uint8_t> data = value.get<std::vector<std::uint8_t>>(column);
  if (value.is_null(column)) {
    SET_VECTOR_ELT(Rf_allocVector(VECSXP, 1), 0, NILSXP);
    return;
  }
  SEXP bytes = Rf_allocVector(RAWSXP, data.size());
  std::copy(data.begin(), data.end(), RAW(bytes));
  SET_VECTOR_ELT(out[column], row, bytes);
}
} // namespace odbc
