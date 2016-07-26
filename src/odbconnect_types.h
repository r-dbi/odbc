#ifndef __ODBCONNECT_TYPES__
#define __ODBCONNECT_TYPES__

#include <Rcpp.h>
#include <sql.h>

inline void freeHDBC(SQLHDBC* hdbc) {
  if (*hdbc) {
    SQLDisconnect(*hdbc);
    SQLFreeHandle(SQL_HANDLE_DBC, *hdbc);
    *hdbc = NULL;
  }
  hdbc = NULL;
}

typedef Rcpp::XPtr<SQLHDBC, Rcpp::PreserveStorage, freeHDBC> XPtrHDBC;
#endif //__ODBCONNECT_TYPES__
