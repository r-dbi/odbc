#pragma once

#define NA_INTEGER64 (0x8000000000000000)

inline int64_t* INTEGER64(SEXP x) {
  return reinterpret_cast<int64_t*>(REAL(x));
}
