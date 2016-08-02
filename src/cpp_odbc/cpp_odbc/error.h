#pragma once
/**
 *  @file odbc/error.h
 *  @date Jan 24, 2012
 *  @author klein
 *  @brief
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include <stdexcept>

namespace cpp_odbc { namespace level2 {
	struct diagnostic_record;
} }

namespace cpp_odbc {

	/**
	 * @brief cpp_odbc classes will translate errors from the underlying unixODBC to this exception.
	 */
	class error : public std::runtime_error{

	public:
		/**
		 * @brief Construct an error directly from a message
		 */
		error(std::string const & message);

		/**
		 * @brief Construct an error from a diagnostic_record
		 */
		error(level2::diagnostic_record const & record);

		virtual ~error() throw();

	};
}
