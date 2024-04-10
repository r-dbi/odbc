# unsupported types gives informative error

    Code
      dbWriteTable(con, "df", df)
    Condition
      Error in `odbcDataType()`:
      ! Can't determine type for column foo.
      Caused by error:
      ! Unsupported type

# dbWriteTable() with `field.types` with `append = TRUE`

    Code
      dbWriteTable(con, "boopery", data.frame(bop = 1), field.types = c(bop = "numeric"),
      append = TRUE)
    Condition
      Error in `dbWriteTable()`:
      ! Cannot specify `field.types` with `append = TRUE`.

# WriteTable() with `overwrite = TRUE` and `append = TRUE`

    Code
      dbWriteTable(con, "boopery", data.frame(bop = 1), overwrite = TRUE, append = TRUE)
    Condition
      Error in `dbWriteTable()`:
      ! `overwrite` and `append` cannot both be "TRUE".

# dbWriteTable(), existing table, `overwrite = FALSE`, `append = FALSE`

    Code
      dbWriteTable(con, "boopery", data.frame(bop = 1), overwrite = FALSE, append = FALSE)
    Condition
      Error in `dbWriteTable()`:
      ! Table boopery exists in database, and both overwrite and append are `FALSE`.

