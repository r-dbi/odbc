test_roundtrip <- function() {
  ctx <- DBItest:::get_default_context()
  context(paste0("roundtrip[", ctx$name, "]"))
  test_that("round tripping data.frames works", {
    library(DBI)
    on.exit(dbRemoveTable(con, "it"))
    con <- DBItest:::connect(ctx)
    it <- iris
    set.seed(42)
    it$Petal.Length <- as.POSIXct(as.numeric(iris$Petal.Length * 10), origin = "2016-01-01", tz = "GMT")
    it$Petal.Width <- as.integer(iris$Petal.Width * 100)
    it$Sepal.Width <- as.Date(iris$Sepal.Width * 100, origin = Sys.time())
    it$Logical <- sample(c(TRUE, FALSE), size = nrow(it), replace = T)
    it$Species <- as.character(it$Species)
    add_na <- function(x) { x[sample(length(x))[1:15]] <- NA; x }
    it[] <- lapply(it, add_na)
    it$Raw <- blob::as.blob(lapply(seq_len(NROW(it)), function(x) as.raw(sample(0:100, size = sample(0:25, 1)))))

    dbWriteTable(con, "it", it, overwrite = TRUE)
    res <- dbReadTable(con, "it")
    expect_equal(it, res)
  })
}
