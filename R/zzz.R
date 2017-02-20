.onUnload <- function (libpath) { # nocov start
  gc() # Force garbage collection of connections
  library.dynam.unload("odbc", libpath)
}

# nocov end
