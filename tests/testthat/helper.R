test_roundtrip <- function(columns = "", invert = TRUE) {
  ctx <- DBItest:::get_default_context()
  context(paste0("roundtrip[", ctx$name, "]"))
  test_that(paste0("[", ctx$name, "] round tripping data.frames works"), {
    on.exit(DBI::dbRemoveTable(con, "it"))
    con <- DBItest:::connect(ctx)
    it <- iris
    set.seed(42)
    it$Petal.Length <- as.POSIXct(as.numeric(iris$Petal.Length * 10), origin = "2016-01-01", tz = "GMT")
    it$Petal.Width <- as.integer(iris$Petal.Width * 100)
    it$Sepal.Width <- as.Date(iris$Sepal.Width * 100, origin = Sys.time())
    it$Logical <- sample(c(TRUE, FALSE), size = nrow(it), replace = T)
    it$Species <- as.character(it$Species)
    it$Raw <- blob::as.blob(lapply(seq_len(NROW(it)), function(x) as.raw(sample(0:100, size = sample(0:25, 1)))))

    # Add a proportion of NA values to a data frame
    add_na <- function(x, p = .1) { is.na(x) <- runif(length(x)) < p; x}
    it[] <- lapply(it, add_na, p = .1)
    if (isTRUE(invert)) {
      it <- it[, names(it) != columns]
    } else {
      it <- it[, names(it) == columns]
    }

    DBI::dbWriteTable(con, "it", it, overwrite = TRUE)
    res <- DBI::dbReadTable(con, "it")
    expect_equal(it, res)
  })
}
