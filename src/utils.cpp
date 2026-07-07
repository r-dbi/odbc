#include <memory>
#include <string>
#include <future>
#include <cstdint>
#include "utils.h"
#if !defined(_WIN32) && !defined(_WIN64)
#include <signal.h>
#endif

#ifndef SQL_DRIVER_CONN_ATTR_BASE
    #define SQL_DRIVER_CONN_ATTR_BASE   0x00004000
#endif
#define SQL_SF_CONN_ATTR_BASE (SQL_DRIVER_CONN_ATTR_BASE + 0x53)
#define SQL_SF_CONN_ATTR_PRIV_KEY (SQL_SF_CONN_ATTR_BASE + 1)
#define SQL_SF_CONN_ATTR_PRIV_KEY_CONTENT (SQL_SF_CONN_ATTR_BASE + 3)
#define SQL_SF_CONN_ATTR_PRIV_KEY_PASSWORD (SQL_SF_CONN_ATTR_BASE + 4)
namespace odbc {
namespace utils {

namespace {

  // UTF-8 <-> UTF-16 transcoding used to bridge [R]'s UTF-8 strings and the
  // wide `nanodbc::string_type` (the ODBC "W" API). This is hand-rolled instead
  // of using std::wstring_convert / std::codecvt_utf8_utf16 because those facets
  // are deprecated since C++17 (warnings on libc++/libstdc++/MSVC, removed in
  // C++26) AND are buggy in several standard libraries: under MinGW/Rtools they
  // could corrupt the heap (crash code 0xC0000374) on malformed input. This
  // single implementation runs identically on every OS and never reads or
  // writes out of bounds: any invalid byte or unpaired surrogate is replaced
  // with U+FFFD (the Unicode REPLACEMENT CHARACTER).
  //
  // The package is always built with NANODBC_USE_UNICODE and without
  // NANODBC_USE_IODBC_WIDE_STRINGS, so nanodbc's wide char is 16-bit (UTF-16)
  // on every platform. Fail loudly if that assumption is ever broken.
  static_assert(sizeof(nanodbc::wide_char_t) == 2,
                "utils.cpp assumes a 16-bit (UTF-16) nanodbc::wide_char_t");

  constexpr char32_t kReplacementChar = 0xFFFD;

  // Append a single Unicode code point to a UTF-16 string.
  inline void append_utf16(nanodbc::string_type& out, char32_t cp)
  {
    if (cp < 0x10000) {
      out.push_back(static_cast<nanodbc::wide_char_t>(cp));
    } else {
      cp -= 0x10000;
      out.push_back(static_cast<nanodbc::wide_char_t>(0xD800 + (cp >> 10)));
      out.push_back(static_cast<nanodbc::wide_char_t>(0xDC00 + (cp & 0x3FF)));
    }
  }

  // Append a single Unicode code point to a UTF-8 string.
  inline void append_utf8(std::string& out, char32_t cp)
  {
    if (cp < 0x80) {
      out.push_back(static_cast<char>(cp));
    } else if (cp < 0x800) {
      out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
      out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
      out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
  }

  nanodbc::string_type utf8_to_wide(const std::string& utf8)
  {
    nanodbc::string_type out;
    out.reserve(utf8.size());
    const std::size_t n = utf8.size();
    std::size_t i = 0;
    while (i < n) {
      const unsigned char lead = static_cast<unsigned char>(utf8[i]);
      char32_t cp;
      std::size_t extra;
      char32_t min_cp;
      if (lead < 0x80) {
        cp = lead; extra = 0; min_cp = 0x0;
      } else if ((lead & 0xE0) == 0xC0) {
        cp = lead & 0x1F; extra = 1; min_cp = 0x80;
      } else if ((lead & 0xF0) == 0xE0) {
        cp = lead & 0x0F; extra = 2; min_cp = 0x800;
      } else if ((lead & 0xF8) == 0xF0) {
        cp = lead & 0x07; extra = 3; min_cp = 0x10000;
      } else {
        // Invalid lead byte: emit replacement and resync on the next byte.
        append_utf16(out, kReplacementChar); ++i; continue;
      }
      if (i + extra >= n) {
        append_utf16(out, kReplacementChar); ++i; continue;
      }
      bool ok = true;
      for (std::size_t k = 1; k <= extra; ++k) {
        const unsigned char cont = static_cast<unsigned char>(utf8[i + k]);
        if ((cont & 0xC0) != 0x80) { ok = false; break; }
        cp = (cp << 6) | (cont & 0x3F);
      }
      // Reject truncated, overlong, out-of-range and surrogate encodings.
      if (!ok || cp < min_cp || cp > 0x10FFFF ||
          (cp >= 0xD800 && cp <= 0xDFFF)) {
        append_utf16(out, kReplacementChar); ++i; continue;
      }
      append_utf16(out, cp);
      i += extra + 1;
    }
    return out;
  }

  std::string wide_to_utf8(const nanodbc::string_type& str)
  {
    std::string out;
    out.reserve(str.size() + str.size() / 2);
    const std::size_t n = str.size();
    for (std::size_t i = 0; i < n; ++i) {
      char32_t cp = static_cast<char16_t>(str[i]);
      if (cp >= 0xD800 && cp <= 0xDBFF) {
        // High surrogate: must be followed by a low surrogate.
        char32_t lo = (i + 1 < n) ? static_cast<char16_t>(str[i + 1]) : 0;
        if (lo >= 0xDC00 && lo <= 0xDFFF) {
          cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
          ++i;
        } else {
          cp = kReplacementChar;
        }
      } else if (cp >= 0xDC00 && cp <= 0xDFFF) {
        // Unpaired low surrogate.
        cp = kReplacementChar;
      }
      append_utf8(out, cp);
    }
    return out;
  }


} // anonymous namespace

  nanodbc::string_type to_nanodbc_string(const std::string& utf8)
  {
    return utf8.empty() ? nanodbc::string_type() : utf8_to_wide(utf8);
  }

  std::string from_nanodbc_string(const nanodbc::string_type& str)
  {
    return str.empty() ? std::string() : wide_to_utf8(str);
  }



  std::shared_ptr< void > serialize_azure_token( const std::string& token )
  {
    unsigned long tokenSize = 2 * token.length();
    std::shared_ptr< void > ret( malloc( 4 + tokenSize ), std::free );
    std::uint32_t* buffer32_t = ( std::uint32_t* ) ret.get();
    buffer32_t[ 0 ] = tokenSize;
    std::uint8_t* buffer8_t = ( std::uint8_t* ) ret.get();
    for ( unsigned int i = 0, j = 0; i < tokenSize; i += 2, j++ )
    {
      buffer8_t[ 4 + i ] = token[ j ];
      buffer8_t[ 4 + i + 1 ] = 0;
    }
    return ret;
  }

  void prepare_connection_attributes(
      long const& timeout,
      Rcpp::Nullable<Rcpp::List> const& r_attributes_,
      std::list< nanodbc::connection::attribute >& attributes,
      std::list< std::shared_ptr< void > >& buffer_context )
  {
    if ( timeout > 0 )
    {
      attributes.push_back(nanodbc::connection::attribute(
          SQL_ATTR_LOGIN_TIMEOUT, SQL_IS_UINTEGER, (void*)(std::intptr_t)timeout));
    }
    if ( r_attributes_.isNotNull() )
    {
      Rcpp::List r_attributes( r_attributes_ );
      if (r_attributes.containsElementNamed( "azure_token" ) &&
          !Rf_isNull(r_attributes["azure_token"]))
      {
        std::string azure_token =
          Rcpp::as<std::string>(r_attributes["azure_token"]);
        std::shared_ptr< void > buffer = serialize_azure_token( azure_token );
        attributes.push_back(nanodbc::connection::attribute(
              SQL_COPT_SS_ACCESS_TOKEN, SQL_IS_POINTER, buffer.get()));
        buffer_context.push_back(buffer);
      }
      if (r_attributes.containsElementNamed("sf_private_key") &&
          !Rf_isNull(r_attributes["sf_private_key"]))
      {
        std::shared_ptr<std::string> priv_key =
          std::make_shared<std::string>(Rcpp::as<std::string>(r_attributes["sf_private_key"]));
        std::shared_ptr< void > buffer(malloc(priv_key->size() + 1), std::free);
        // Copy null terminator as well
        std::memcpy(buffer.get(), priv_key->c_str(), priv_key->size() + 1);
        attributes.push_back(nanodbc::connection::attribute(
               SQL_SF_CONN_ATTR_PRIV_KEY_CONTENT, SQL_NTS, buffer.get()));
        buffer_context.push_back(buffer);
      }
      if (r_attributes.containsElementNamed("sf_private_key_password") &&
          !Rf_isNull(r_attributes["sf_private_key_password"]))
      {
        std::shared_ptr<std::string> key_pass =
          std::make_shared<std::string>(Rcpp::as<std::string>(r_attributes["sf_private_key_password"]));
        std::shared_ptr< void > buffer(malloc(key_pass->size() + 1), std::free);
        // Copy null terminator as well
        std::memcpy(buffer.get(), key_pass->c_str(), key_pass->size() + 1);
        attributes.push_back(nanodbc::connection::attribute(
               SQL_SF_CONN_ATTR_PRIV_KEY_PASSWORD, SQL_NTS, buffer.get()));
        buffer_context.push_back(buffer);
      }
    }
  }

  void run_interruptible(const std::function<void()>& exec_fn, const std::function<void()>& cancel_fn,
                         const std::function<void()>& cleanup_fn)
  {
    std::exception_ptr eptr;
#if !defined(_WIN32) && !defined(_WIN64)
    sigset_t set, old_set;
    sigemptyset(&set);
    sigaddset(&set, SIGINT);
    int rc = pthread_sigmask(SIG_BLOCK, &set, &old_set);
    if ( rc != 0 )
    {
      // Unable to properly mask SIGINT from execution thread
      raise_warning("Unexpected behavior when creating execution thread.  Signals to interrupt execution may not be caught.");
    }
#endif
    auto future = std::async(std::launch::async, [&exec_fn, &eptr]() {
      try {
        exec_fn();
      } catch (...) {
        eptr = std::current_exception();
      }
      return;
    });
#if !defined(_WIN32) && !defined(_WIN64)
    pthread_sigmask(SIG_SETMASK, &old_set, NULL);
#endif
    std::future_status status;
    do {
      status = future.wait_for(std::chrono::seconds(1));
      if (status != std::future_status::ready) {
        try { Rcpp::checkUserInterrupt(); }
        catch (const Rcpp::internal::InterruptedException& e) {
          raise_message("Caught user interrupt, attempting a clean exit...");
          cancel_fn();
        } catch (...) { throw; }
      }
    } while (status != std::future_status::ready);
    if (eptr) {
      // An exception was thrown in the thread
      try { cleanup_fn(); std::rethrow_exception(eptr); }
      catch (const odbc_error& e) { raise_error(e); }
      catch (...) { raise_message("Unknown exception while executing"); throw; };
    }
  }

  void raise_message(const std::string& message) {
    Rcpp::Environment pkg = Rcpp::Environment::namespace_env("cli");
    Rcpp::Function r_method = pkg["cli_inform"];
    Rcpp::CharacterVector argMessage =
      Rcpp::CharacterVector::create(Rcpp::Named("i", message));
    r_method(argMessage);
  }

  void raise_warning(const std::string& message) {
    Rcpp::Environment pkg = Rcpp::Environment::namespace_env("cli");
    Rcpp::Function r_method = pkg["cli_warn"];
    Rcpp::CharacterVector argMessage =
      Rcpp::CharacterVector::create(Rcpp::Named("!", message));
    r_method(argMessage);
  }

  void raise_error(const std::string& message) {
    Rcpp::Environment pkg = Rcpp::Environment::namespace_env("cli");
    Rcpp::Function r_method = pkg["cli_abort"];
    Rcpp::CharacterVector argMessage =
      Rcpp::CharacterVector::create(Rcpp::Named("x", message));
    r_method(argMessage);
  }

  void raise_error(const odbc_error& e) {
    Rcpp::Environment pkg = Rcpp::Environment::namespace_env("odbc");
    Rcpp::Function r_method = pkg["rethrow_database_error"];
    r_method(e.what());
  }

}}
