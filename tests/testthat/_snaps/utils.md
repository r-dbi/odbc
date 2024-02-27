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
      ! Unable to locate the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

# databricks() errors informatively when spark ini isn't writeable

    Code
      write_spark_lines("", ".", ".", call2("databricks"))
    Condition
      Error in `databricks()`:
      ! Detected needed changes to the driver configuration file at ., but the file was not writeable.
      i Please make the changes outlined at https://solutions.posit.co/connections/db/databases/databricks/#troubleshooting-apple-macos-users.

