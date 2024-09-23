#pragma once

#include "nanodbc.h"
#include "sql_types.h"
#include "time_zone.h"
#include <Rcpp.h>
// Important that this header is included after Rcpp.h
#include "Iconv.h"

namespace odbc {

enum bigint_map_t {
  i64_to_integer64,
  i64_to_integer,
  i64_to_double,
  i64_to_character,
};

class odbc_result;

class odbc_connection {
public:
  friend odbc_result;
  odbc_connection(
      std::string const& connection_string,
      std::string const& timezone = "UTC",
      std::string const& timezone_out = "UTC",
      std::string const& encoding = "",
      std::string const& name_encoding = "",
      bigint_map_t const& bigint_mapping = i64_to_integer64,
      long const& timeout = 0,
      Rcpp::Nullable<Rcpp::List> const& r_attributes = R_NilValue,
      bool const& interruptible_execution = true);

  std::shared_ptr<nanodbc::connection> connection() const;

  void begin();
  void commit();
  void rollback();
  bool has_active_result() const;
  bool is_current_result(odbc_result* result) const;
  bool supports_transactions() const;
  bool get_data_any_order() const;

  void cancel_current_result();
  void set_current_result(odbc_result* r);
  bool has_result() const;

  cctz::time_zone timezone() const;
  std::string timezone_out_str() const;
  const std::shared_ptr<Iconv> output_encoder() const;
  const std::shared_ptr<Iconv> column_name_encoder() const;

  bigint_map_t get_bigint_mapping() const;

private:
  std::shared_ptr<nanodbc::connection> c_;
  std::unique_ptr<nanodbc::transaction> t_;
  odbc_result* current_result_;
  cctz::time_zone timezone_;
  cctz::time_zone timezone_out_;
  std::string timezone_out_str_;
  bigint_map_t bigint_mapping_;
  std::shared_ptr<Iconv> output_encoder_;
  std::shared_ptr<Iconv> column_name_encoder_;
  bool interruptible_execution_;
};
} // namespace odbc
