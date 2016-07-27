#include <sql.h>
#include <sqlext.h>
#include "utils.h"
#include "odbconnect-init.h"
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <Rcpp.h>

class ODBCConnection : boost::noncopyable {
  public:
  ODBCConnection(std::string x) : hdbc_(NULL) {
    Rcpp::Rcout << odbcEnv << '\n';
    ODBCerror(
        SQLAllocHandle(SQL_HANDLE_DBC, odbcEnv, &hdbc_),
        "Failed to allocate handle (%i)");
  }
  XPtr<ODBCConnection> connect(std::string x) {
    SQLCHAR connectStr[BUF_LEN];
    SQLSMALLINT connectStrLen;

    ODBCerror(SQLDriverConnect(
          hdbc_,
          NULL,
          asSqlChar(x),
          x.size(),
          connectStr,
          BUF_LEN,
          &connectStrLen,
          SQL_DRIVER_NOPROMPT));

  Rcout << hdbc_ << ':' << connectStrLen << ':' << connectStr << '\n';

  return XPtr<ODBCConnection>(this);
  }
  ~ODBCConnection() {
    if (hdbc_) {
      //SQLDisconnect(hdbc);
      SQLFreeHandle(SQL_HANDLE_DBC, hdbc_);
    }
    hdbc_ = NULL;
  }

  private:
    SQLHDBC hdbc_;
};

typedef boost::shared_ptr<ODBCConnection> ODBCConnectionPtr;
