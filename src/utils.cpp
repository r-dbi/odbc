#include <sql.h>
#include <Rcpp.h>
#include "utils.h"

void ODBCerror(SQLRETURN retcode, const char * msg) {
  if (!(retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO)) {
    stop(msg, retcode);
  }
}
