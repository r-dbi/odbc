#include <sql.h>
#include <sqlext.h>
#include "utils.h"
#include "odbconnect-init.h"
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <Rcpp.h>
#include "api.h"
#include "string_buffer.h"
#include "Handles.h"

typedef boost::shared_ptr<ConnectionHandle> ConnectionPtr;
