#pragma once

#include <Rcpp.h>
#ifdef _WIN32
#undef Realloc
#undef Free
#include <windows.h>
#endif
#include "sqlext.h"

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
