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

