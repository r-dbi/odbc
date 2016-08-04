#pragma once

#include <turbodbc/type_code.h>
#include <string>

namespace turbodbc {

struct column_info {
	std::string name;
	type_code type;
	bool supports_null_values;
};

}
