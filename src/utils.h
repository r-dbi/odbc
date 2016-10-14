#pragma once

#include <Rcpp.h>
#include "r_types.h"

using namespace odbconnect;

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
                     //Rf_setAttrib(out[j], R_ClassSymbol, Rf_mkString("Date"));
                     break;
                   }
      case date_time_t: {
                     out[j] = Rf_allocVector(REALSXP, n);
                     //Rf_setAttrib(out[j], Rf_mkString("tzone"), Rf_mkString("UTC"));
                     //Rf_setAttrib(out[j], R_ClassSymbol, Rcpp::CharacterVector::create("POSIXct", "POSIXt"));
                     break;
                     //out[j].attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
                     //out[j].attr("tzone") = "UTC";
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
    //SEXP attr;
    //DUPLICATE_ATTRIB(out[j], attr);
    out[j] = Rf_lengthgets(df[j], n);
    //SET_ATTRIB(out[j], attr);
  }

  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  return out;
}
