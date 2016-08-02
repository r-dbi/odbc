#pragma once
/**
 *  @file connection.h
 *  @date 16.05.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-11-28 15:54:55 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21211 $
 *
 */

#include "cpp_odbc/statement.h"

#include "sql.h"

#include <memory>
#include <string>

namespace cpp_odbc {

/**
 * @brief This interface represents a connection with an ODBC database
 */
class connection : public std::enable_shared_from_this<connection> {
public:
	connection(connection const &) = delete;
	connection & operator=(connection const &) = delete;

	/**
	 * @brief Create and return a new statement
	 * @return A pointer to a new statement
	 */
	std::shared_ptr<statement const> make_statement() const;

	/**
	 * @brief Set the attribute to the given long value
	 * @param attribute An ODBC constant which represents the attribute which shall be set
	 * @param value The new value for the attribute
	 */
	void set_attribute(SQLINTEGER attribute, long value) const;

	/**
	 * @brief End the current transaction by committing all changes to the database
	 */
	void commit() const;

	/**
	 * @brief End the current transaction by reverting all changes on the database
	 */
	void rollback() const;

	/**
	 * @brief Retrieve some information in string format
	 * @param info_type A constant representing the information to retrieve
	 * @return The string value associated with the information
	 */
	std::string get_string_info(SQLUSMALLINT info_type) const;

	/**
	 * @brief Retrieve some information in integer format
	 * @param info_type A constant representing the information to retrieve
	 * @return The value associated with the information
	 */
	SQLUINTEGER get_integer_info(SQLUSMALLINT info_type) const;

	virtual ~connection();
protected:
	connection();
private:
	virtual std::shared_ptr<statement const> do_make_statement() const = 0;
	virtual void do_set_attribute(SQLINTEGER attribute, long value) const = 0;
	virtual void do_commit() const = 0;
	virtual void do_rollback() const = 0;
	virtual std::string do_get_string_info(SQLUSMALLINT info_type) const = 0;
	virtual SQLUINTEGER do_get_integer_info(SQLUSMALLINT info_type) const = 0;
};

}
