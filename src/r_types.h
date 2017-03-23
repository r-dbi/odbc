#pragma once

#include <Rcpp.h>
#include "sql_types.h"

namespace odbc {
  typedef enum {
    logical_t,
    integer_t,
    double_t,
    date_t,
    datetime_t,
    string_t,
    raw_t,
  } r_type;
}
