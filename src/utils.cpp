#include <memory>
#include <string>
#include <future>
#include "utils.h"
#if !defined(_WIN32) && !defined(_WIN64)
#include <signal.h>
#endif
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
    std::shared_ptr< void > buffer;
    if ( r_attributes_.isNotNull() )
    {
      Rcpp::List r_attributes( r_attributes_ );
      if ( r_attributes.containsElementNamed( "azure_token" ) &&
          !Rf_isNull(r_attributes["azure_token"]) )
      {
        std::string azure_token =
          Rcpp::as<std::string>(r_attributes["azure_token"]);
        std::shared_ptr< void > buffer = serialize_azure_token( azure_token );
        attributes.push_back(nanodbc::connection::attribute(
              SQL_COPT_SS_ACCESS_TOKEN, SQL_IS_POINTER, buffer.get()));
        buffer_context.push_back( buffer );
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
      Rcpp::warning("Unable to properly mask SIGINT from execution thread.");
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
          pretty_print_message("Caught user interrupt, attempting a clean exit...");
          cleanup_fn();
        } catch (...) { throw; }
      }
    } while (status != std::future_status::ready);
    if (eptr) {
      // An exception was thrown in the thread
      try { std::rethrow_exception(eptr); }
      catch (const odbc_error& e) { e.pretty_print(); }
      catch (...) { pretty_print_message("Unknown exception while executing"); throw; };
    }
  }

  void pretty_print_message(const std::string& message, const bool is_warning) {
    Rcpp::Environment pkg = Rcpp::Environment::namespace_env("odbc");
    Rcpp::Function r_print_message = pkg["print_message"];
    r_print_message(message, is_warning ? "w" : "i");
  }

}}
