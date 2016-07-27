#include <sql.h>
#include <sqlext.h>
#include "utils.h"
#include "odbconnect_types.h"
#include "odbconnect-init.h"

#include <Rcpp.h>
using namespace Rcpp;

extern "C" {

  SQLHANDLE odbcEnv = NULL;
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

// [[Rcpp::export]]
List listDrivers() {

  SQLCHAR driverDesc[BUF_LEN], driverAttr[BUF_LEN];
  SQLSMALLINT driverDescLen, driverAttrLen;

  std::vector<std::string> drivers, attr;

  while(SQLDrivers(odbcEnv, SQL_FETCH_NEXT,
      driverDesc, sizeof(driverDesc), &driverDescLen,
      driverAttr, sizeof(driverAttr), &driverAttrLen
    ) == SQL_SUCCESS) {
    drivers.push_back(std::string(driverDesc, driverDesc + driverDescLen));
    attr.push_back(std::string(driverAttr, driverAttr + driverAttrLen));
  }

  return List::create(
    drivers,
    attr
  );
}

// [[Rcpp::export]]
List listDataSources() {

  SQLCHAR dataSourceDesc[BUF_LEN], dataSourceAttr[BUF_LEN];
  SQLSMALLINT dataSourceDescLen, dataSourceAttrLen;

  std::vector<std::string> dataSources, attr;

  while(SQLDataSources(odbcEnv, SQL_FETCH_NEXT,
      dataSourceDesc, sizeof(dataSourceDesc), &dataSourceDescLen,
      dataSourceAttr, sizeof(dataSourceAttr), &dataSourceAttrLen
    ) == SQL_SUCCESS) {
    dataSources.push_back(std::string(dataSourceDesc, dataSourceDesc + dataSourceDescLen));
    attr.push_back(std::string(dataSourceAttr, dataSourceAttr + dataSourceAttrLen));
  }

  return List::create(
    dataSources,
    attr
  );
}
