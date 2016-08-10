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
	 * @brief Retrieve a RObject which contains the next batch results.
	 * @return Returned object is an empty list in case there are no results.
	 */
	Rcpp::RObject fetch_next_batch() const;
	/**
	 * @brief Retrieve a RObject with the full results.
	 * @return Returned object is an empty list in case there are no results.
	 */
	Rcpp::RObject fetch_all() const;

private:
	result_set& base_result_;
	std::vector<type_code> types_;
};

} }
