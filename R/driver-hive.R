#' @export
#' @rdname DBI-classes
setClass("Hive", contains = "OdbcConnection")

# only need to override dbQuteString when x is character.
# DBI:::quote_string just returns x when it is of class SQL, so no need to override that.
#' @rdname DBI-methods
setMethod("dbQuoteString", c("Hive", "character"),
  function(conn, x, ...) {
    if (is(x, "SQL")) {
      return(x)
    }
    x <- gsub("'", "\\\\'", enc2utf8(x))
    if (length(x) == 0L) {
      DBI::SQL(character())
    } else {
      str <- paste0("'", x, "'")
      str[is.na(x)] <- "NULL"
      DBI::SQL(str)
    }
  }
)
