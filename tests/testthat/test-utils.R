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
