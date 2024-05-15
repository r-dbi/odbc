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

# errors if auth fails

    Code
      . <- databricks_args1()
    Condition
      Error in `DBI::dbConnect()`:
      ! x Failed to detect ambient Databricks credentials.
      i Supply `uid` and `pwd` to authenticate manually.

# must supply both uid and pwd

    Code
      databricks_auth_args("host", uid = "uid")
    Condition
      Error in `DBI::dbConnect()`:
      ! Both `uid` and `pwd` must be specified for manual authentication.
      i Or leave both unset for automated authentication.

# dbConnect method errors informatively re: httpPath (#787)

    Code
      dbConnect(databricks(), httpPath = "boop", HTTPPath = "bop")
    Condition
      Error in `dbConnect()`:
      ! Exactly one of `httpPath` or `HTTPPath` must be supplied.

---

    Code
      dbConnect(databricks(), HTTPPath = 1L)
    Condition
      Error in `dbConnect()`:
      ! `HTTPPath` must be a single string or `NULL`, not the number 1.

---

    Code
      dbConnect(databricks(), httpPath = 1L)
    Condition
      Error in `dbConnect()`:
      ! `httpPath` must be a single string or `NULL`, not the number 1.

