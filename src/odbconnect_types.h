#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include <boost/shared_ptr.hpp>
#include "turbodbc/cursor.h"

typedef Rcpp::XPtr<boost::shared_ptr<turbodbc::connection const> > connection_ptr;
typedef Rcpp::XPtr<boost::shared_ptr<turbodbc::cursor const> > cursor_ptr;

#endif //__ODBCONNECT_TYPES__
