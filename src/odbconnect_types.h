#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "Rcpp.h"
#include "odbc_result.h"
#include "odbc_connection.h"

typedef Rcpp::XPtr<std::shared_ptr<odbconnect::odbc_connection>> connection_ptr;
typedef Rcpp::XPtr<odbconnect::odbc_result> result_ptr;

#endif //__ODBCONNECT_TYPES__
