#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include <boost/shared_ptr.hpp>
#include "turbodbc/cursor.h"

typedef Rcpp::XPtr<std::shared_ptr<turbodbc::connection>> connection_ptr;
typedef Rcpp::XPtr<turbodbc::cursor> cursor_ptr;

#endif //__ODBCONNECT_TYPES__
