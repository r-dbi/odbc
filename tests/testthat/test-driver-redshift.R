test_that("the 'uid' and 'pwd' arguments suppress IAM auth", {
  args <- redshift_args(driver = "driver", uid = "uid", pwd = "pwd")
  expect_equal(args$uid, "uid")
  expect_equal(args$pwd, "pwd")
  expect_equal(args$iam, NULL)
})

test_that("IAM credentials in environment variables are handled correctly", {
  if(is_windows()) {
    # paws.common binary tarball for windows 4.1
    # is 0.5.x which does not have paws::locate_credentials
    # exported.
    # For exmaple, https://cran.rstudio.com/bin/windows/contrib/4.1/
    skip_unless_r(">= 4.2")
  }
  withr::local_envvar(
    AWS_ACCESS_KEY_ID = "access-key-id",
    AWS_SECRET_ACCESS_KEY = "secret-access-key",
    AWS_SESSION_TOKEN = "session-token"
  )
  args <- redshift_args(driver = "driver")
  expect_equal(args$accessKeyId, "access-key-id")
  expect_equal(args$secretAccessKey, "secret-access-key")
  expect_equal(args$sessionToken, "session-token")
})

