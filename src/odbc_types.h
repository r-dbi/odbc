#ifndef __ODBC_TYPES__
#define __ODBC_TYPES__

#include "Rcpp.h"
#include "odbc_result.h"
#include "odbc_connection.h"

typedef Rcpp::XPtr<std::shared_ptr<odbc::odbc_connection>> connection_ptr;
typedef Rcpp::XPtr<odbc::odbc_result> result_ptr;

#endif //__ODBC_TYPES__
