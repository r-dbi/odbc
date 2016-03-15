.onUnload <- function (libpath) {
  library.dynam.unload("odbconnect", libpath)
}
