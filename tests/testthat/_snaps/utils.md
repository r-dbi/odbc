# id_field checks inputs

    Code
      id_field(DBI::Id("a"), "foo")
    Condition
      Error:
      ! `field` must be one of "catalog", "schema", or "table", not "foo".
    Code
      id_field(DBI::Id("a", "b", "c", "d"))
    Condition
      Error:
      ! Identifier must be length 1, 2, or 3.

# configure_spark() errors informatively on failure to install unixODBC

    Code
      databricks()
    Condition
      Error in `databricks()`:
      ! Unable to install the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

