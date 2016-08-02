#pragma once
/**
 *  @file level1_connector.h
 *  @date 07.03.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include "cpp_odbc/level2/api.h"
#include <memory>

namespace cpp_odbc { namespace level1 {

class api;

} }

namespace cpp_odbc { namespace level2 {


/**
 * @brief This connector implements the level2::api by forwarding calls to a level1::api.
 *        Thereby, this class does all exception handling, data type translation,
 *        and return value generation.
 */
class level1_connector : public api {
public:
	/**
	 * @brief Construct a new connector which issues calls to the given api
	 * @param level1_api Methods of this instance are called in all other methods
	 *        of this class.
	 */
	level1_connector(std::shared_ptr<level1::api const> level1_api);

private:
	statement_handle do_allocate_statement_handle(connection_handle const & input_handle) const final;
	connection_handle do_allocate_connection_handle(environment_handle const & input_handle) const final;
	environment_handle do_allocate_environment_handle() const final;
	void do_free_handle(statement_handle & handle) const final;
	void do_free_handle(connection_handle & handle) const final;
	void do_free_handle(environment_handle & handle) const final;
	diagnostic_record do_get_diagnostic_record(statement_handle const & handle) const final;
	diagnostic_record do_get_diagnostic_record(connection_handle const & handle) const final;
	diagnostic_record do_get_diagnostic_record(environment_handle const & handle) const final;
	void do_set_environment_attribute(environment_handle const & handle, SQLINTEGER attribute, long value) const final;
	void do_set_connection_attribute(connection_handle const & handle, SQLINTEGER attribute, long value) const final;
	void do_establish_connection(connection_handle & handle, std::string const & connection_string) const final;
	void do_disconnect(connection_handle & handle) const final;
	void do_end_transaction(connection_handle const & handle, SQLSMALLINT completion_type) const final;
	std::string do_get_string_connection_info(connection_handle const & handle, SQLUSMALLINT info_type) const final;
	SQLUINTEGER do_get_integer_connection_info(connection_handle const & handle, SQLUSMALLINT info_type) const final;
	void do_bind_column(statement_handle const & handle, SQLUSMALLINT column_id, SQLSMALLINT column_type, multi_value_buffer & column_buffer) const final;
	void do_bind_input_parameter(statement_handle const & handle, SQLUSMALLINT parameter_id, SQLSMALLINT value_type, SQLSMALLINT parameter_type, multi_value_buffer & parameter_values) const final;
	void do_execute_prepared_statement(statement_handle const & handle) const final;
	void do_execute_statement(statement_handle const & handle, std::string const & sql) const final;
	bool do_fetch_scroll(statement_handle const & statement_handle, SQLSMALLINT fetch_orientation, SQLLEN fetch_offset) const final;
	void do_free_statement(statement_handle const & handle, SQLUSMALLINT option) const final;
	long do_get_integer_column_attribute(statement_handle const & handle, SQLUSMALLINT column_id, SQLUSMALLINT field_identifier) const final;
	long do_get_integer_statement_attribute(statement_handle const & handle, SQLINTEGER attribute) const final;
	std::string do_get_string_column_attribute(statement_handle const & handle, SQLUSMALLINT column_id, SQLUSMALLINT field_identifier) const final;
	short int do_number_of_result_columns(statement_handle const & handle) const final;
	short int do_number_of_parameters(statement_handle const & handle) const final;
	void do_prepare_statement(statement_handle const & handle, std::string const & sql) const final;
	void do_set_statement_attribute(statement_handle const & handle, SQLINTEGER attribute, long value) const final;
	void do_set_statement_attribute(statement_handle const & handle, SQLINTEGER attribute, SQLULEN * pointer) const final;
	SQLLEN do_row_count(statement_handle const & handle) const final;
	column_description do_describe_column(statement_handle const & handle, SQLUSMALLINT column_id) const final;
	column_description do_describe_parameter(statement_handle const & handle, SQLUSMALLINT parameter_id) const final;
	bool do_more_results(statement_handle const & handle) const final;

	std::shared_ptr<level1::api const> level1_api_;
};

} }
