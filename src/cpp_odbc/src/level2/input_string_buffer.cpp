/**
 *  @file input_string_buffer.cpp
 *  @date 21.03.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include "cpp_odbc/level2/input_string_buffer.h"

#include <cstring>

namespace cpp_odbc { namespace level2 {

input_string_buffer::input_string_buffer(std::string const & data) :
	data_(data.size() + 1)
{
	memcpy(data_.data(), data.data(), data_.size());
}

std::size_t input_string_buffer::size() const
{
	return data_.size() - 1;
}

unsigned char * input_string_buffer::data_pointer()
{
	return data_.data();
}

} }
