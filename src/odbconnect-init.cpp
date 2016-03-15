#include <sql.h>
#include <sqlext.h>

#include <Rcpp.h>
using namespace Rcpp;

static SQLHANDLE odbcEnv = NULL;

extern "C" {

  void R_init_odbconnect(DllInfo *info) {
    SQLRETURN retval = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &odbcEnv);

    if (retval != SQL_SUCCESS && retval != SQL_SUCCESS_WITH_INFO)
      stop("Failed to initialised odbconnect");

    SQLSetEnvAttr(odbcEnv, SQL_ATTR_ODBC_VERSION, (SQLPOINTER) SQL_OV_ODBC3,
      SQL_IS_INTEGER);
  }

  void R_unload_odbconnect(DllInfo *info) {
    if (odbcEnv != NULL)
      SQLFreeHandle(SQL_HANDLE_ENV, odbcEnv);
    odbcEnv = NULL;
  }

}

