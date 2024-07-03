# dbConnect() errors informatively without unixODBC (#782)

    Code
      test_con("SQLITE")
    Condition
      Error in `dbConnect()`:
      ! Unable to locate the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

