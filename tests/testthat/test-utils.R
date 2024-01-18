test_that("parse_size works", {
  expect_error(parse_size("foo"), "Must be a positive integer")
  expect_error(parse_size(TRUE), "Must be a positive integer")
  expect_error(parse_size(0), "Must be a positive integer")
  expect_error(parse_size(-1), "Must be a positive integer")
  expect_error(parse_size(-.1), "Must be a positive integer")
  expect_error(parse_size(.1), "Must be a positive integer")
  expect_error(parse_size("0"), "Must be a positive integer")
  expect_error(parse_size("1"), "Must be a positive integer")
  expect_error(parse_size(Inf), "Must be a positive integer")
  expect_error(parse_size(NULL), "Must be a positive integer")
  expect_error(parse_size(1:2), "Must be a positive integer")
  expect_error(parse_size(numeric()), "Must be a positive integer")
  expect_error(parse_size(integer()), "Must be a positive integer")

  expect_identical(parse_size(1L), 1)
  expect_identical(parse_size(1), 1)
  expect_identical(parse_size(.Machine$integer.max), as.numeric(.Machine$integer.max))
  expect_identical(parse_size(.Machine$integer.max + 1), .Machine$integer.max + 1)
})

test_that("id_field extracts correct elements", {
  expect_equal(id_field(DBI::Id("z"), "table"), "z")

  expect_equal(id_field(DBI::Id("y", "z"), "schema"), "y")
  expect_equal(id_field(DBI::Id("y", "z"), "table"), "z")

  expect_equal(id_field(DBI::Id("x", "y", "z"), "catalog"), "x")
  expect_equal(id_field(DBI::Id("x", "y", "z"), "schema"), "y")
  expect_equal(id_field(DBI::Id("x", "y", "z"), "table"), "z")
})

test_that("id_field checks inputs", {
  expect_snapshot(error = TRUE, {
    id_field(DBI::Id("a"), "foo")
    id_field(DBI::Id("a", "b", "c", "d"))
  })
})

test_that("getSelector", {
  # If no wild cards are detected always use exact comparison / ignore `exact` argument
  expect_equal(getSelector("mykey", "myvalue", exact = TRUE), " AND mykey = 'myvalue'")
  expect_equal(getSelector("mykey", "myvalue", exact = FALSE), " AND mykey = 'myvalue'")

  # If `value` contains wild cards, respect `exact`argument
  expect_equal(getSelector("mykey", "myvalu_", exact = TRUE), " AND mykey = 'myvalu_'")
  expect_equal(getSelector("mykey", "myvalu_", exact = FALSE), " AND mykey LIKE 'myvalu_'")

  expect_equal(getSelector("mykey", "myvalu%", exact = TRUE), " AND mykey = 'myvalu%'")
  expect_equal(getSelector("mykey", "myvalu%", exact = FALSE), " AND mykey LIKE 'myvalu%'")

  # ... unless argument is '%' - always use 'LIKE' since this is most likely the
  # desired comparison / ignore `exact` argument
  expect_equal(getSelector("mykey", "%", exact = TRUE), " AND mykey LIKE '%'")
  expect_equal(getSelector("mykey", "%", exact = FALSE), " AND mykey LIKE '%'")
})
