#pragma once

#include <turbodbc/field_translator.h>

namespace turbodbc { namespace field_translators {

/**
 * @brief Translates 64 bit integer values into buffer elements and vice versa
 */
class int64_translator : public field_translator {
public:
	int64_translator();
	~int64_translator();
private:
	field do_make_field(char const * data_pointer) const final;
	void do_set_field(cpp_odbc::writable_buffer_element & element, field const & value) const final;
};

} }
