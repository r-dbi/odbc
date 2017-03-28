#pragma once

#ifdef _WIN32
#undef Realloc
#undef Free
#include <windows.h>
#endif
#include <sqlext.h>
