#pragma once

#include <turbodbc/field.h>
#include <turbodbc/type_code.h>
#include <cpp_odbc/multi_value_buffer.h>
#include <sqltypes.h>

namespace turbodbc {

/**
 * @brief Translate buffer elements to fields and vice versa
 */
class field_translator {
public:
	/**
	 * @brief Return a field based on the buffer element
	 */
	nullable_field make_field(cpp_odbc::buffer_element const & element) const;

	/**
	 * @brief Set a buffer element to the value of a field
	 */
	void set_field(cpp_odbc::writable_buffer_element & element, nullable_field const & value) const;

	field_translator (field_translator const &) = delete;
	field_translator & operator=(field_translator const &) = delete;

	virtual ~field_translator();
protected:
	field_translator();
private:
	virtual field do_make_field(char const * data_pointer) const = 0;
	virtual void do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const = 0;
};

}
