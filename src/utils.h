#include <string>
#include <sql.h>
#include <Rcpp.h>

using namespace Rcpp;

inline const SQLCHAR* asSqlCharC(const std::string& x) {
  return reinterpret_cast<const SQLCHAR*>(x.c_str());
}

// This removes the const qualifier, use only when the input will be read only!
inline SQLCHAR* asSqlChar(const std::string& x) {
  return const_cast<SQLCHAR*>(asSqlCharC(x));
}

// A wrapper around SQLCHAR * that frees memory if necessary
//class Xml2String {
  //SQLCHAR* string_;
  //bool free_;

//public:
  //Sql2String(): string_(NULL), free_(false) {}

  //Sql2String(SQLCHAR* string): string_(string), free_(true) {}

  //// Pointers into structs are const, so don't need to be freed
  //Sql2String(const SQLCHAR* string): string_((SQLCHAR*) string), free_(false) {}

  //// Some strings are regular strings
  //Sql2String(const char* string): string_((SQLCHAR*) string), free_(false) {}

  //~Sql2String() {
    //try {
      //if (free_ && string_ != NULL)
        //xmlFree(string_);
    //} catch (...) {}
  //}

  //std::string asStdString(std::string missing = "") {
    //if (string_ == NULL)
      //return missing;

    //return std::string((char*) string_);
  //}

  //SEXP asRString(SEXP missing = NA_STRING) {
    //if (string_ == NULL)
      //return missing;

    //return Rf_mkCharCE((char*) string_, CE_UTF8);
  //};
//};


void ODBCerror(SQLRETURN retcode, const char * msg = "Error (%i)") {
  if (!(retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO)) {
    stop(msg, retcode);
  }
}
