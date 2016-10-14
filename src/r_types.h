#pragma once
#include <Rcpp.h>

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
      case RAWSXP:
        return raw_t;
      default:
        Rcpp::stop("Unsupported column type %s", Rf_type2char(TYPEOF(x)));
    }

    // We should never actually get here
    return string_t;
  }

  //nullable_field nullable_field_from_R_object(Rcpp::RObject const & x, r_type type, size_t i) {
    //switch(type) {
      //case logical_t: {
        //if (ISNA(LOGICAL(x)[i])) {
          //return {};
        //} else {
          //return field(static_cast<bool>(LOGICAL(x)[i]));
        //}
      //}
      //case integer_t: {
        //if (ISNA(INTEGER(x)[i])) {
          //return {};
        //} else {
          //return field(static_cast<int64_t>(INTEGER(x)[i]));

        //}
      //}
      //case double_t: {
        //if (ISNA(REAL(x)[i])) {
          //return {};
        //} else {
          //return field(REAL(x)[i]);

        //}
      //}
      //case string_t: {
        //if (STRING_ELT(x, i) == NA_STRING) {
          //return {};
        //} else {
          //return field(std::string(Rf_translateCharUTF8(STRING_ELT(x, i))));
        //}
      //}
      //case date_time_t: {
        //if (ISNA(REAL(x)[i])) {
          //return {};
        //}
        //return field(boost::posix_time::from_time_t(static_cast<time_t>(std::floor(REAL(x)[i]))));
      //}
      //case date_t: {
        //if (ISNA(REAL(x)[i])) {
          //return {};
        //}
        //time_t t = 24*60*60 * std::floor(REAL(x)[i]);      // (fractional) days since epoch to seconds since epoch
        //tm d_tm = *Rcpp::gmtime_(&t);
        //return field(boost::gregorian::date_from_tm(d_tm));
      //}
      //default:
        //Rcpp::stop("Don't know how to handle vector of type %s.",
            //Rf_type2char(TYPEOF(x)));
    //}
    //return {};
  //}

  //nullable_field nullable_field_from_R_object(Rcpp::RObject x, size_t i = 0) {
    //return nullable_field_from_R_object(x, get_r_type(x), i);
  //}

std::vector<r_type> column_types(nanodbc::result const & r) {
  std::vector<r_type> types;
  types.reserve(r.columns());
  for (short i = 0;i < r.columns();++i) {

    short type = r.column_datatype(i);
    switch (type)
    {
      case SQL_BIT:
      case SQL_TINYINT:
      case SQL_SMALLINT:
      case SQL_INTEGER:
      case SQL_BIGINT:
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
      // Date
      case SQL_DATE:
      case SQL_TYPE_DATE:
        types.push_back(date_t);
        break;
      // Time
      case SQL_TIME:
      case SQL_TIMESTAMP:
      case SQL_TYPE_TIMESTAMP:
      case SQL_TYPE_TIME:
        types.push_back(date_time_t);
        break;
      case SQL_CHAR:
      case SQL_VARCHAR:
      case SQL_WCHAR:
      case SQL_WVARCHAR:
      case SQL_LONGVARCHAR:
        types.push_back(string_t);
        break;
      case SQL_BINARY:
      case SQL_VARBINARY:
      case SQL_LONGVARBINARY:
        types.push_back(raw_t);
        break;
      default:
        types.push_back(string_t);
        Rcpp::warning("Unknown field type (%s) in column %s", type, r.column_name(i));
        break;
    }
  }
  return types;
}
}
