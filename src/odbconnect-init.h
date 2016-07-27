#ifndef __ODBCONNECT_INIT__
#define __ODBCONNECT_INIT__

#include <sql.h>

extern "C" {
  extern SQLHANDLE odbcEnv;
}
static const size_t BUF_LEN = 1024;

#endif //__ODBCONNECT_INIT__
