# databricks host validates inputs

    Code
      databricks_host("")
    Condition
      Error:
      ! No Databricks workspace URL provided.
      i Either supply `workspace` argument or set env var `DATABRICKS_HOST`.

