#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "Rcpp.h"
#include "cpp_odbc/connection.h"

typedef Rcpp::XPtr<std::shared_ptr<cpp_odbc::connection const>> connection_ptr;
typedef Rcpp::XPtr<std::shared_ptr<cpp_odbc::statement const>> statement_ptr;

#endif //__ODBCONNECT_TYPES__
