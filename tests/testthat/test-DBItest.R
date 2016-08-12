DBItest::make_context(odbconnect(), list("DSN=database1"), tweaks = DBItest::tweaks(), name = "odbconnect")
DBItest::test_all(c(
  "package_name",
  ".*stress.*", # TODO: Enable
  "quote_identifier_not_vectorized",
  "invalid_query",
  NULL
))
