#ifndef __ODBC_TYPES__
#define __ODBC_TYPES__

#include "odbc_connection.h"
#include "odbc_result.h"

#include "Rcpp.h"

typedef Rcpp::XPtr<std::shared_ptr<odbc::odbc_connection>> connection_ptr;
typedef Rcpp::XPtr<odbc::odbc_result> result_ptr;

#endif //__ODBC_TYPES__
