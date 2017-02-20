 # nocov start
.onUnload <- function (libpath) {
  gc() # Force garbage collection of connections
  library.dynam.unload("odbc", libpath)
}

.onLoad <- function(libname, pkgname) {
  is_windows <- identical(.Platform$OS.type, "windows")

  # If TZDIR is not set we need to set it to R's timezone database on windows,
  # we can use the standard timezone database elsewhere.
  if (is_windows) {
    if (!nzchar(Sys.getenv("TZDIR"))) Sys.setenv("TZDIR" = file.path(R.home(), "share", "zoneinfo"))
  }
}

# nocov end
