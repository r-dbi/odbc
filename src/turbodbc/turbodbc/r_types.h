#pragma once
#include <Rcpp.h>

namespace turbodbc {
  typedef enum {
    logical_t,
    integer_t,
    double_t,   // output only
    date_t,
    date_time_t,
    string_t
  } r_type;
  r_type get_r_type(Rcpp::RObject x) {
    switch(TYPEOF(x)) {
      case LGLSXP:
        return logical_t;
      case INTSXP:
        return integer_t;
      case REALSXP: {
        Rcpp::RObject klass_o = x.attr("class");
        if (klass_o == R_NilValue) {
          return double_t;
        }
        std::string klass = Rcpp::as<std::string>(klass_o);
        if (klass == "Date") {
          return date_t;
        }
        if (klass == "POSIXct") {
          return date_time_t;
        }
        return double_t;
      }
      case STRSXP:
        return string_t;
      default:
        Rcpp::stop("Unsupported column type %s", Rf_type2char(TYPEOF(x)));
    }

    // We should never actually get here
    return string_t;
  }
}
