#ifndef STRING_BUFFER_H_
#define STRING_BUFFER_H_

#include <array>
#include <string>
#include <vector>
#include <algorithm>

// Used as SQLCHAR* replacement for output strings
class string_buffer {
  public:
    string_buffer(signed short int capacity) :
  data_(capacity),
  size_(0) { }

    signed short int capacity() const {
      return data_.capacity();
    }

    unsigned char * data_pointer() {
      return data_.data();
    }

    signed short int * size_pointer() {
      return &size_;
    }

    operator std::string() const {
      char const * characters = reinterpret_cast<char const *>(data_.data());
      return std::string(characters, size_);
    }

  private:
    std::vector<unsigned char> data_;
    signed short int size_;
};

// Used as a SQLCHAR* replacement for input strings
//
class input_string_buffer {
public:
  input_string_buffer(std::string const & data) :
  data_(data.size() + 1) {
    std::copy(data.begin(), data.end(), data_.begin());
  }

  std::size_t size() const {
    return data_.size() - 1;
  }
  unsigned char * data_pointer() {
    return data_.data();
  }
  private:
    std::vector<unsigned char> data_;
};

// Used for fixed state buffers such as 5 character SQLSTATE codes
template  <std::size_t Capacity>
class fixed_length_string_buffer {
  public:
    fixed_length_string_buffer() {}

    std::size_t capacity() const {
      return Capacity;
    }

    unsigned char * data_pointer() {
      return data_.data();
    }

    operator std::string() const {
      char const * characters = reinterpret_cast<char const *>(data_.data());
      return std::string(characters, Capacity);
    }

  private:
    std::array<unsigned char, Capacity> data_;
};

#endif // STRING_BUFFER_H_
