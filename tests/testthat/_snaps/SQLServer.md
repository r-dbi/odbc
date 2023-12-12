# Create / write to temp table

    Temporary flag is set to true, but table name doesn't use # prefix

---

    Temporary flag is set to true, but table name doesn't use # prefix

# timeout is respected

    Code
      dbGetQuery(con, "WaitFor Delay '00:00:03'; SELECT 1 as x", timeout = 1)
    Condition
      Error:
      ! nanodbc/nanodbc.cpp:1769: 00000
      [Microsoft][ODBC Driver 18 for SQL Server]Query timeout expired 
      <SQL> 'WaitFor Delay '00:00:03'; SELECT 1 as x'

