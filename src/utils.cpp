#include <memory>
#include <string>
#include "utils.h"

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
}}
