#pragma once

#include <Rcpp.h>
#include "sqlext.h"

namespace odbconnect {
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
