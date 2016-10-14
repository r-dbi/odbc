#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "nanodbc.h"
#include "Rcpp.h"

typedef Rcpp::XPtr<nanodbc::connection> connection_ptr;
typedef Rcpp::XPtr<nanodbc::result> result_ptr;

#endif //__ODBCONNECT_TYPES__
