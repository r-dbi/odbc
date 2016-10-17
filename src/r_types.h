#pragma once

#include <Rcpp.h>
#include "sqlext.h"

namespace odbconnect {
  typedef enum {
    logical_t,
    integer_t,
    double_t,   // output only
    date_t,
    date_time_t,
    string_t,
    raw_t,
  } r_type;
}
