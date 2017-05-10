#ifndef READ_ICONV_H_
#define READ_ICONV_H_

/* This file originally from
 * https://github.com/cran/readr/blob/4c2d7c77810a3cb66586727179c339192964aa3d/src/Iconv.h
 */

#include "R_ext/Riconv.h"
#include <errno.h>

class Iconv {
  void* cd_;
  std::string buffer_;

public:
  Iconv(const std::string& from, const std::string& to = "UTF-8");
  virtual ~Iconv();

  SEXP makeSEXP(const char* start, const char* end, bool hasNull = true);
  std::string makeString(const char* start, const char* end);

private:
  // Returns number of characters in buffer
  size_t convert(const char* start, const char* end);
};

#endif
