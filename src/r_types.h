#pragma once

#include "sql_types.h"
#include <Rcpp.h>

namespace odbc {
typedef enum {
  logical_t,
  integer_t,
  integer64_t,
  double_t,
  date_t,
  datetime_t,
  time_t,
  string_t,
  ustring_t,
  raw_t,
} r_type;
}
