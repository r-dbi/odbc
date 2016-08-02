#ifndef DIAGNOSTIC_RECORD_H_
#define DIAGNOSTIC_RECORD_H_

#include <vector>
#include <string>
#include <sstream>
#include <Rcpp.h>

class DiagnosticRecord {
  public:
    void push_back(const std::string& odbc_state, int native_code, const std::string& message) {
      odbc_state_.push_back(odbc_state);
      native_code_.push_back(native_code);
      message_.push_back(message);
    }

    std::string message() const {
      if (odbc_state_.size() == 0) {
        return "";
      }

      std::stringstream buf;
      buf << odbc_state_.at(0) << '\t' << native_code_.at(0) << '\t' << message_.at(0);
      for (size_t i = 1; i < odbc_state_.size(); ++i) {
        buf << '\n' << odbc_state_.at(i) << '\t' << native_code_.at(i) << '\t' << message_.at(i);
      }
      return buf.str();
    }
  private:
    std::vector<std::string> odbc_state_;
    std::vector<int> native_code_;
    std::vector<std::string> message_;
};

class OdbcError : Rcpp::exception {
  public:

  OdbcError(const std::string & message) :
    Rcpp::exception(message.c_str()) { }

  OdbcError(const DiagnosticRecord& record) :
    Rcpp::exception(record.message().c_str())
  { }

};

#endif // DIAGNOSTIC_RECORD_H_
