#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "Rcpp.h"
#include <odbc_result.h>
#include "nanodbc.h"

typedef Rcpp::XPtr<nanodbc::connection> connection_ptr;
typedef Rcpp::XPtr<odbconnect::odbc_result> result_ptr;

#endif //__ODBCONNECT_TYPES__
