# dbWriteTable errors if field.types don't exist (#271)

    Code
      sqlCreateTable(con, "foo", iris, field.types = list(bar = "[int]"))
    Condition
      Warning:
      Some columns in `field.types` not in the input, missing columns:
        - 'bar'
    Output
      <SQL> CREATE TABLE "foo" (
        "Sepal.Length" FLOAT,
        "Sepal.Width" FLOAT,
        "Petal.Length" FLOAT,
        "Petal.Width" FLOAT,
        "Species" varchar(255),
        "bar" [int]
      )
      

# can create / write to temp table

    `temporary` is `TRUE`, but table name doesn't use # prefix.

---

    `temporary` is `TRUE`, but table name doesn't use # prefix.

