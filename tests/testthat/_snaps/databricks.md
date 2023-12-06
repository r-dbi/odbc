# errors if can't find driver

    Code
      databricks_default_driver()
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to automatically find Databricks/Spark ODBC driver.
      i Set `driver` to known driver name or path.

# databricks host validates inputs

    Code
      databricks_host("")
    Condition
      Error in `DBI::dbConnect()`:
      ! No Databricks workspace URL provided.
      i Either supply `workspace` argument or set env var `DATABRICKS_HOST`.

# warns if auth fails

    Code
      . <- databricks_args1()
    Condition
      Warning in `DBI::dbConnect()`:
      x Failed to detect ambient Databricks credentials.
      i Supply `uid` or `pwd` to authenticate manually.

