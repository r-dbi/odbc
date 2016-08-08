#pragma once

#include <turbodbc/result_sets/row_based_result_set.h>
#include <turbodbc/field.h>
#include <turbodbc/field_translator.h>
#include "Rcpp.h"

namespace turbodbc { namespace result_sets {

/**
 * @brief This class adapts a result_set to provide row-based access via
 *        the nullable_field data type
 */
class r_result_set {
public:
	/**
	 * @brief Create a new r_result_set which presents data contained
	 *        in the base result set in a row-based fashion
	 */
	r_result_set(result_set & base);

	/**
	 * @brief Retrieve information about each column in the result set
	 */
	std::vector<column_info> get_column_info() const;

	/**
	 * @brief Retrieve a RObject which belongs to the next row.
	 * @return Returned object is an empty list in case there is no additional row
	 */
	Rcpp::RObject fetch_all();

private:
	result_set& base_result_;
	std::vector<type_code> types_;
};

} }
