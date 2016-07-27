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
    ODBCerror(
        SQLAllocHandle(SQL_HANDLE_DBC, odbcEnv, &hdbc_),
        "Failed to allocate handle (%i)");
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

    connect_string_ = std::string(reinterpret_cast<char *>(connectStr), connectStrLen);
  }
  ~ODBCConnection() {
    if (hdbc_) {
      //SQLDisconnect(hdbc);
      SQLFreeHandle(SQL_HANDLE_DBC, hdbc_);
    }
    hdbc_ = NULL;
  }

  std::string format() {
    return connect_string_;
  }

  private:
    SQLHDBC hdbc_;
    std::string connect_string_;
};

typedef boost::shared_ptr<ODBCConnection> ODBCConnectionPtr;
