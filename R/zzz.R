.onUnload <- function (libpath) {
  gc() # Force garbage collection of connections
  library.dynam.unload("odbconnect", libpath)
}
