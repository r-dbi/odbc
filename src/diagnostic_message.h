#ifndef DIAGNOSTIC_MESSAGE_H_
#define DIAGNOSTIC_MESSAGE_H_

#include <vector>
#include <string>
#include <sstream>

class DiagnosticRecords {
  public:
    void push_back(const std::string& odbc_state, int native_code, const std::string& message) {
      odbc_state_.push_back(odbc_state);
      native_code_.push_back(native_code);
      message_.push_back(message);
    }

    std::string message() {
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
#endif // DIAGNOSTIC_MESSAGE_H_
