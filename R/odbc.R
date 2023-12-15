#' Set the Transaction Isolation Level for a Connection
#'
#' @param levels One or more of \Sexpr[stage=render, results=rd]{odbc:::choices_rd(names(odbc:::transactionLevels()))}.
#' @inheritParams DBI::dbDisconnect
#' @seealso \url{https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/setting-the-transaction-isolation-level}
#' @export
#' @noMd
#' @examples
#' \dontrun{
#' # Can use spaces or underscores in between words.
#' odbcSetTransactionIsolationLevel(con, "read uncommitted")
#'
#' # Can also use the full constant name.
#' odbcSetTransactionIsolationLevel(con, "SQL_TXN_READ_UNCOMMITTED")
#' }
odbcSetTransactionIsolationLevel <- function(conn, levels) {
  # Convert to lowercase, spaces to underscores, remove sql_txn prefix
  levels <- tolower(levels)
  levels <- gsub(" ", "_", levels)
  levels <- sub("sql_txn_", "", levels)
  levels <- match.arg(tolower(levels), names(transactionLevels()), several.ok = TRUE)

  set_transaction_isolation(conn@ptr, transactionLevels()[levels])
}
