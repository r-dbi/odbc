#include <memory>
#include <string>
#include <future>
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
        std::shared_ptr< void > buffer(malloc(priv_key->size()), std::free);
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
        std::shared_ptr< void > buffer(malloc(key_pass->size()), std::free);
        // Copy null terminator as well
        std::memcpy(buffer.get(), key_pass->c_str(), key_pass->size() + 1);
        attributes.push_back(nanodbc::connection::attribute(
               SQL_SF_CONN_ATTR_PRIV_KEY_PASSWORD, SQL_NTS, buffer.get()));
        buffer_context.push_back(buffer);
      }
    }
  }

  void run_interruptible(const std::function<void()>& exec_fn, const std::function<void()>& cleanup_fn)
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
          cleanup_fn();
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
