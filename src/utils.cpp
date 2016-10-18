#include "utils.h"
namespace odbconnect {

std::vector<std::string> column_names(nanodbc::result const & r) {
  std::vector<std::string> names;
  names.reserve(r.columns());
  for (short i = 0;i < r.columns();++i) {
    names.push_back(r.column_name(i));
  }
  return names;
}

double make_timestamp(nanodbc::timestamp const & ts)
{
  tm t;
  t.tm_sec = t.tm_min = t.tm_hour = t.tm_isdst = 0;

  t.tm_year = ts.year - 1900;
  t.tm_mon = ts.month - 1;
  t.tm_mday = ts.day;
  t.tm_hour = ts.hour;
  t.tm_min = ts.min;
  t.tm_sec = ts.sec;

  return Rcpp::mktime00(t) + ts.fract;
}

Rcpp::List create_dataframe(std::vector<r_type> types, std::vector<std::string> names, int n) {
  int num_cols = types.size();
  Rcpp::List out(num_cols);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  for (int j = 0; j < num_cols; ++j) {
    switch (types[j]) {
      case integer_t: out[j] = Rf_allocVector(INTSXP, n); break;
      case odbconnect::double_t: out[j] = Rf_allocVector(REALSXP, n); break;
      case date_t: {
        out[j] = Rf_allocVector(REALSXP, n);
        Rcpp::as<Rcpp::RObject>(out[j]).attr("class") = "Date";
        break;
      }
      case date_time_t: {
        out[j] = Rf_allocVector(REALSXP, n);
        Rcpp::as<Rcpp::RObject>(out[j]).attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
        Rcpp::as<Rcpp::RObject>(out[j]).attr("tzone") = "UTC";
        break;
      }
      case string_t: out[j] = Rf_allocVector(STRSXP, n); break;
      case raw_t: out[j] = Rf_allocVector(VECSXP, n); break;
      case logical_t: out[j] = Rf_allocVector(LGLSXP, n); break;
    }
  }
  return out;
}

Rcpp::List resize_dataframe(Rcpp::List df, int n) {
  int p = df.size();

  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {

    SEXP attr;
    bool has_attributes = ATTRIB(out[j]) != R_NilValue;
    if (has_attributes) {
      SHALLOW_DUPLICATE_ATTRIB(attr, out[j]);
    }
    out[j] = Rf_lengthgets(df[j], n);
    if (has_attributes) {
      SET_ATTRIB(out[j], attr);
    }
  }

  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  return out;
}

std::vector<r_type> column_types(Rcpp::DataFrame const & df) {
  std::vector<r_type> types;
  types.reserve(df.size());
  for (short i = 0;i < df.size();++i) {
    switch(TYPEOF(df[i])) {
      case LGLSXP: types.push_back(logical_t); break;
      case INTSXP: types.push_back(integer_t); break;
      case REALSXP: {
        Rcpp::RObject x = df[i];
        if (x.inherits("Date")) {
          types.push_back(date_t);
        } else if (x.inherits("POSIXct")) {
          types.push_back(date_time_t);
        }
        types.push_back(double_t);
        break;
      }
      case STRSXP: types.push_back(string_t); break;
      case RAWSXP: types.push_back(raw_t); break;
      default:
        Rcpp::stop("Unsupported column type %s", Rf_type2char(TYPEOF(df[i])));
    }
  }

  return types;
}

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

Rcpp::List result_to_dataframe(nanodbc::result & r, int n_max) {

  auto types = column_types(r);

  int n = (n_max < 0) ? 100: n_max;

  Rcpp::List out = create_dataframe(types, column_names(r), n);
  int row = 0;
  for (auto &vals : r) {
    if (row >= n) {
      if (n_max < 0) {
        n *= 2;
        out = resize_dataframe(out, n);
      } else {
        break;
      }
    }
    for (short col = 0;col < r.columns(); ++col) {
      switch(types[col]) {
        case integer_t: INTEGER(out[col])[row] = vals.get<int>(col, NA_INTEGER); break;
        case date_t:
        case date_time_t: {
          double val;
          if (vals.is_null(col)) {
            val = NA_REAL;
          } else {
            val = make_timestamp(vals.get<nanodbc::timestamp>(col));
          }

          REAL(out[col])[row] = val;
          break;
        }
        case odbconnect::double_t:
                        REAL(out[col])[row] = vals.get<double>(col, NA_REAL); break;
        case string_t: {
          SEXP val;
          if (vals.is_null(col)) {
            val = NA_STRING;
          } else {
            val = Rf_mkCharCE(vals.get<nanodbc::string_type>(col).c_str(), CE_UTF8);
          }
          SET_STRING_ELT(out[col], row, val); break;
        }
                        //case raw_t: out[j] = Rf_allocVector(VECSXP, n); break;
                        //case logical_t: out[j] = Rf_allocVector(LGLSXP, n); break;
      }
    }

    ++row;
  }
  if (row < n) {
    out = resize_dataframe(out, row);
  }
  return out;
}
}
