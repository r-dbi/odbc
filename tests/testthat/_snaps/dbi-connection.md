# show method prints only host if no user is defined

    Code
      con
    Output
      <OdbcConnection> localhost

# show method prints DISCONNECTED if not valid

    Code
      con
    Output
      <OdbcConnection> localhost
        DISCONNECTED

# show method does not print server if it is not available

    Code
      con
    Output
      <OdbcConnection>

# dbQuoteIdentifier() errors informatively

    Code
      dbQuoteIdentifier(con, NA_character_)
    Condition
      Error in `dbQuoteIdentifier()`:
      ! `x` can't be `NA`.

# dbConnect() errors informatively without unixODBC (#782)

    Code
      test_con("SQLITE")
    Condition
      Error in `dbConnect()`:
      ! Unable to locate the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

