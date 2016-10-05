#pragma once
#include <Rcpp.h>
#include <turbodbc/field.h>

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
        if (x.inherits("Date")) {
          return date_t;
        }
        if (x.inherits("POSIXct")) {
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

  nullable_field nullable_field_from_R_object(Rcpp::RObject const & x, r_type type, size_t i) {
    switch(type) {
      case logical_t: {
        if (ISNA(LOGICAL(x)[i])) {
          return {};
        } else {
          return field(static_cast<bool>(LOGICAL(x)[i]));
        }
      }
      case integer_t: {
        if (ISNA(INTEGER(x)[i])) {
          return {};
        } else {
          return field(static_cast<long>(INTEGER(x)[i]));

        }
      }
      case double_t: {
        if (ISNA(REAL(x)[i])) {
          return {};
        } else {
          return field(REAL(x)[i]);

        }
      }
      case string_t: {
        if (STRING_ELT(x, i) == NA_STRING) {
          return {};
        } else {
          return field(std::string(Rf_translateCharUTF8(STRING_ELT(x, i))));
        }
      }
      case date_time_t: {
        if (ISNA(REAL(x)[i])) {
          return {};
        }
        return field(boost::posix_time::from_time_t(static_cast<time_t>(std::floor(REAL(x)[i]))));
      }
      case date_t: {
        if (ISNA(REAL(x)[i])) {
          return {};
        }
        time_t t = 24*60*60 * std::floor(REAL(x)[i]);      // (fractional) days since epoch to seconds since epoch
        tm d_tm = *Rcpp::gmtime_(&t);
        return field(boost::gregorian::date_from_tm(d_tm));
      }
      default:
        Rcpp::stop("Don't know how to handle vector of type %s.",
            Rf_type2char(TYPEOF(x)));
    }
    return {};
  }

  nullable_field nullable_field_from_R_object(Rcpp::RObject x, size_t i = 0) {
    return nullable_field_from_R_object(x, get_r_type(x), i);
  }
}
