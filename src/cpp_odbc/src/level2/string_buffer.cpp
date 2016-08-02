/**
 *  @file string_buffer.cpp
 *  @date 07.03.2014
 *  @author mkoenig
 *  @brief 
 *
 *  $LastChangedDate: 2014-11-28 11:59:59 +0100 (Fr, 28 Nov 2014) $
 *  $LastChangedBy: mkoenig $
 *  $LastChangedRevision: 21206 $
 *
 */

#include "cpp_odbc/level2/string_buffer.h"

namespace cpp_odbc { namespace level2 {

string_buffer::string_buffer(signed short int capacity) :
	data_(capacity),
	used_size_(0)
{
}

signed short int string_buffer::capacity() const
{
	return data_.capacity();
}

unsigned char * string_buffer::data_pointer()
{
	return data_.data();
}

signed short int * string_buffer::size_pointer()
{
	return &used_size_;
}

string_buffer::operator std::string() const
{
	char const * characters = reinterpret_cast<char const *>(data_.data());
	return std::string(characters, used_size_);
}



} }
