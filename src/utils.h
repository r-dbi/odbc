#ifndef R_ODBC_UTILS_H
#define R_ODBC_UTILS_H

#ifndef SQL_COPT_SS_ACCESS_TOKEN
#define SQL_COPT_SS_ACCESS_TOKEN (1256UL)
#endif

#include <Rcpp.h>
#include "sql_types.h"
#include "odbc_result.h"
#include "nanodbc.h"

namespace odbc {
namespace utils {
  /// \brief Prepare connection attributes
  ///
  /// Parse [R] named list of connection attributes and translate into
  /// nanodbc::connection::attributes (tuple) format.
  ///
  /// \param timeout Connection timeout.  This is a legacy argument that was
  /// a separate parameter prior to introduction of the more generic attributes
  /// API.
  /// \param r_attributes_ Named list of connection attributes.  It is NULL
  /// by default in dbConnect call.
  /// \param attributes List of nanodbc::connection::attributes.  Holds
  /// translated results.
  /// \param buffer_context Connection attribtues may consist of memory
  /// allocations that are not to be freed until after the call to
  /// nanodbc::connection(...) or nanodbc::connect(...).  Developers should
  /// wrap these allocations in a shared pointer with an appropriate deleter.
  /// To make sure the allocation is not released before the connection is
  /// established, one may store any shared pointers in this list and carry
  /// them into the appropriate context as needed.
  void prepare_connection_attributes(
      long const& timeout,
      Rcpp::Nullable<Rcpp::List> const& r_attributes_,
      std::list< nanodbc::connection::attribute >& attributes,
      std::list< std::shared_ptr< void > >& buffer_context );

  /// \brief Serialize authentication token for Microsoft Azure.
  ///
  /// Format is described in:
  /// https://learn.microsoft.com/en-us/sql/connect/odbc/using-azure-active-directory?view=sql-server-ver16#authenticating-with-an-access-token
  ///
  /// \param token The authentication token.
  /// \return A shared pointer to the buffer containing the serialized structure.
  std::shared_ptr< void > serialize_azure_token( const std::string& token );

  /// \brief Wrapper to allow for interruptible execution of argument function
  ///
  /// The execution function is relegated to a separate thread.
  /// On the main thread, we wait for the execution to complete while
  /// at the same time checking for user interrupts every one second.
  ///
  /// \param exec_fn Function executed on a separate thread.  Exceptions
  /// are caught and re-thrown on the main thread.
  /// \param cleanup_fn Function executed on main thread in the event a
  /// user interrupt is caught.
  void run_interruptible(const std::function<void()>& exec_fn, const std::function<void()>& cleanup_fn);

  /// \brief Entry point for package::cli::cli_inform
  ///
  /// \param message Message to be shown.
  void raise_message(const std::string& message);

  /// \brief Entry point for package::cli::cli_warn
  ///
  /// \param message Message to be shown.
  void raise_warning(const std::string& message);

  /// \brief Entry point for package::cli::cli_abort
  ///
  /// \param message Message to be shown.
  void raise_error(const std::string& message);

  /// \brief Entry point for package::odbc:::rethrow_database_error
  ///
  /// On the [R] side, the message ( e.what() ) is parsed and
  /// displayed in a user friendly / multi-line format.
  /// \param e (nanodbc::database_)Exception to be raised.
  void raise_error(const odbc_error& e);
}}
#endif
