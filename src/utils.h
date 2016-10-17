#pragma once

#include <Rcpp.h>
#include "nanodbc.h"
#include "r_types.h"

namespace odbconnect {
std::vector<std::string> column_names(nanodbc::result const & r);
Rcpp::List create_dataframe(std::vector<r_type> types, std::vector<std::string> names, int n);
Rcpp::List resize_dataframe(Rcpp::List df, int n);
std::vector<r_type> column_types(Rcpp::DataFrame const & df);
std::vector<r_type> column_types(nanodbc::result const & r);
Rcpp::List result_to_dataframe(nanodbc::result & r, int n_max = -1);
}
