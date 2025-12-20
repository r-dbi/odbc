test_that("can connect to snowflake", {
  key_exists <- Sys.getenv("SNOWFLAKE_PRIVATE_KEY_EXISTS")
  if (nchar(key_exists) == 0) {
    skip("Secret SNOWFLAKE_PRIVATE_KEY not available.")
  }

  con <- test_con("SNOWFLAKE")
})

test_that("an account ID is required", {
  withr::local_envvar(SNOWFLAKE_ACCOUNT = "")
  # Create an empty config dir so we get a clean "no connections" error
  config_dir <- withr::local_tempdir()
  withr::local_envvar(SNOWFLAKE_HOME = config_dir)
  expect_snapshot(snowflake_args(driver = "driver"), error = TRUE)
})

test_that("environment variables are handled correctly", {
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SF_PARTNER = "test_partner"
  )
  args <- snowflake_args(
    pwd = "pwd",
    uid = "user",
    driver = "driver"
  )
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
  expect_equal(args$application, "test_partner")
})

test_that("environment variables can be overridden with parameters", {
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "account",
    SF_PARTNER = "test_partner"
  )
  args <- snowflake_args(
    account = "testorg-test_account",
    pwd = "pwd",
    uid = "user",
    driver = "driver",
    application = "myapp"
  )
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
  expect_equal(args$application, "myapp")
})

test_that("the 'uid' and 'pwd' arguments suppress automated auth", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    uid = "uid",
    pwd = "pwd"
  )
  expect_equal(args$uid, "uid")
  expect_equal(args$pwd, "pwd")
  expect_equal(args$authenticator, NULL)
})

test_that("both 'uid' and 'pwd' are required when present", {
  expect_snapshot(
    snowflake_args(
      account = "testorg-test_account",
      driver = "driver",
      uid = "uid",
    ),
    error = TRUE
  )
})

test_that("alternative authenticators are supported", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "externalbrowser"
  )
  expect_equal(args$authenticator, "externalbrowser")
})

test_that("can pass only `uid` with non-NULL `authenticator` (#817, #889)", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "externalbrowser",
    uid = "boop"
  )
  expect_equal(args$uid, "boop")
  expect_equal(args$authenticator, "externalbrowser")

  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "SNOWFLAKE_JWT",
    uid = "boop"
  )
  expect_equal(args$uid, "boop")
  expect_equal(args$authenticator, "SNOWFLAKE_JWT")
})

test_that("we error if we can't find ambient credentials", {
  withr::local_envvar(SF_PARTNER = "")
  local_mocked_bindings(
    snowflake_auth_args = function(...) list()
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

test_that("we hint viewer-based credentials on Connect", {
  withr::local_envvar(SF_PARTNER = "")
  local_mocked_bindings(
    snowflake_auth_args = function(...) list(),
    running_on_connect = function() TRUE
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

test_that("tokens can be requested from a Connect server", {
  skip_if_not_installed("connectcreds")

  connectcreds::local_mocked_connect_responses(token = "token")
  expect_equal(
    snowflake_auth_args("testorg-test_account"),
    list(authenticator = "oauth", token = "token")
  )
})

test_that("the default driver falls back to a known driver name", {
  local_mocked_bindings(
    snowflake_default_driver_paths = function() character(),
    odbcListDrivers = function() list(name = c("bar", "Snowflake"))
  )
  expect_equal(snowflake_default_driver(), "Snowflake")
})

test_that("we error if we can't find the driver", {
  local_mocked_bindings(
    snowflake_default_driver_paths = function() character(),
    odbcListDrivers = function() list()
  )
  expect_snapshot(snowflake_default_driver(), error = TRUE)
})

test_that("Workbench-managed credentials are detected correctly", {
  # Emulate the connections.toml file written by Workbench.
  sf_home <- tempfile("posit-workbench")
  dir.create(sf_home)
  writeLines(
    c(
      '[workbench]',
      'account = "testorg-test_account"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver")
  expect_equal(args$token, "token")
  expect_equal(args$authenticator, "oauth")
})

test_that("Workbench-managed credentials are ignored for other accounts", {
  # Emulate the connections.toml file written by Workbench.
  sf_home <- tempfile("posit-workbench")
  dir.create(sf_home)
  writeLines(
    c(
      '[workbench]',
      'account = "nonmatching"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_HOME = sf_home,
    SF_PARTNER = "test_partner"
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

# --- Configuration File Support Tests ---

test_that("snowflake_config_dir() respects SNOWFLAKE_HOME", {
  withr::local_envvar(SNOWFLAKE_HOME = "/custom/path")
  expect_equal(snowflake_config_dir(), "/custom/path")

  withr::local_envvar(SNOWFLAKE_HOME = "~/custom")
  expect_equal(snowflake_config_dir(), path.expand("~/custom"))
})

test_that("snowflake_config_dir() falls back to platform defaults on macOS", {
  skip_on_os(c("windows", "linux"))
  # Use a non-existent SNOWFLAKE_HOME to force fallback
  withr::local_envvar(SNOWFLAKE_HOME = "")
  # Create a temp dir and use it as home where ~/.snowflake doesn't exist
  tmp_home <- tempfile()
  dir.create(tmp_home)
  withr::defer(unlink(tmp_home, recursive = TRUE))
  withr::local_envvar(HOME = tmp_home)

  expect_equal(
    snowflake_config_dir(),
    file.path(tmp_home, "Library/Application Support/snowflake")
  )
})

test_that("load_snowflake_config() loads connections.toml correctly", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[default]',
      'account = "defaultaccount"',
      'user = "defaultuser"',
      'password = "defaultpwd"',
      '',
      '[prod]',
      'account = "prodaccount"',
      'user = "produser"',
      'warehouse = "PROD_WH"'
    ),
    file.path(config_dir, "connections.toml")
  )

  # Bypass permission checks for test
  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true")

  config <- load_snowflake_config(config_dir)

  expect_equal(config$default_connection_name, "default")
  expect_equal(config$connections$default$account, "defaultaccount")
  expect_equal(config$connections$prod$account, "prodaccount")
  expect_equal(config$connections$prod$warehouse, "PROD_WH")
})

test_that("load_snowflake_config() loads config.toml correctly", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      'default_connection_name = "prod"',
      '',
      '[connections.dev]',
      'account = "devaccount"',
      'user = "devuser"'
    ),
    file.path(config_dir, "config.toml")
  )

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true")

  config <- load_snowflake_config(config_dir)

  expect_equal(config$default_connection_name, "prod")
  expect_equal(config$connections$dev$account, "devaccount")
})

test_that("load_snowflake_config() merges connections.toml over config.toml", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      'default_connection_name = "prod"',
      '',
      '[connections.dev]',
      'account = "from_config"',
      'user = "config_user"'
    ),
    file.path(config_dir, "config.toml")
  )

  writeLines(
    c(
      '[dev]',
      'account = "from_connections"',
      'user = "connections_user"',
      'warehouse = "DEV_WH"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true")

  config <- load_snowflake_config(config_dir)

  # connections.toml completely overwrites
  expect_equal(config$default_connection_name, "prod")  # From config.toml
  expect_equal(config$connections$dev$account, "from_connections")
  expect_equal(config$connections$dev$warehouse, "DEV_WH")
})

test_that("load_snowflake_config() handles missing files gracefully", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  config <- load_snowflake_config(config_dir)

  expect_equal(config$default_connection_name, "default")
  expect_equal(length(config$connections), 0)
})

test_that("SNOWFLAKE_CONNECTIONS env var overrides file-based connections", {
  skip_if_not_installed("toml")

  withr::local_envvar(
    SNOWFLAKE_CONNECTIONS = '[prod]
account = "envaccount"
user = "envuser"',
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  config_dir <- withr::local_tempdir()

  writeLines(
    c('[prod]', 'account = "fileaccount"'),
    file.path(config_dir, "connections.toml")
  )

  config <- load_snowflake_config(config_dir)

  expect_equal(config$connections$prod$account, "envaccount")
})

test_that("SNOWFLAKE_DEFAULT_CONNECTION_NAME env var overrides config file", {
  skip_if_not_installed("toml")

  withr::local_envvar(
    SNOWFLAKE_DEFAULT_CONNECTION_NAME = "staging",
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  config_dir <- withr::local_tempdir()

  writeLines(
    'default_connection_name = "prod"',
    file.path(config_dir, "config.toml")
  )

  config <- load_snowflake_config(config_dir)

  expect_equal(config$default_connection_name, "staging")
})

test_that("Named connection loads and merges with kwargs", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[prod]',
      'account = "prodaccount"',
      'user = "produser"',
      'password = "prodpwd"',
      'warehouse = "PROD_WH"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  args <- snowflake_args(
    connection_name = "prod",
    driver = "driver",
    warehouse = "OVERRIDE_WH"
  )

  expect_equal(args$account, "prodaccount")
  expect_equal(args$uid, "produser")
  expect_equal(args$pwd, "prodpwd")
  expect_equal(args$warehouse, "OVERRIDE_WH")  # programmatic override
})

test_that("Config file with user and authenticator (no password) works", {
  skip_if_not_installed("toml")

  config_dir <- tempfile()
  dir.create(config_dir)

  withr::defer(unlink(config_dir, recursive = TRUE))

  # This mirrors a typical externalbrowser config - user + authenticator, no password
  writeLines(
    c(
      '[default]',
      'account = "testaccount"',
      'user = "user@example.com"',
      'authenticator = "externalbrowser"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # This should not error with "matched by multiple actual arguments"
  args <- snowflake_args(driver = "driver")

  expect_equal(args$account, "testaccount")
  expect_equal(args$uid, "user@example.com")
  expect_equal(args$authenticator, "externalbrowser")
  # pwd should be NULL (not required with externalbrowser)
  expect_null(args$pwd)
})

test_that("Config file authenticator is preserved in final args", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[default]',
      'account = "testaccount"',
      'user = "testuser"',
      'authenticator = "SNOWFLAKE_JWT"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  args <- snowflake_args(driver = "driver")

  # Authenticator from config should be in final args
  expect_equal(args$authenticator, "SNOWFLAKE_JWT")
  expect_equal(args$uid, "testuser")
})

test_that("Default connection loads when no args provided", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[default]',
      'account = "defaultaccount"',
      'user = "defaultuser"',
      'password = "defaultpwd"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SNOWFLAKE_ACCOUNT = "",
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  args <- snowflake_args(driver = "driver")

  expect_equal(args$account, "defaultaccount")
  expect_equal(args$uid, "defaultuser")
  expect_equal(args$pwd, "defaultpwd")
})

test_that("Programmatic params skip file loading", {
  skip_if_not_installed("toml")

  # Create config files that should NOT be read
  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[default]',
      'account = "shouldnotload"',
      'user = "shouldnotload"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  args <- snowflake_args(
    account = "programmatic",
    driver = "driver",
    uid = "user",
    pwd = "password"
  )

  expect_equal(args$account, "programmatic")
  expect_equal(args$uid, "user")
})

test_that("SNOWFLAKE_ACCOUNT env var only used in programmatic mode", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c(
      '[default]',
      'account = "configaccount"',
      'user = "configuser"',
      'password = "configpwd"'
    ),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SNOWFLAKE_ACCOUNT = "envaccount",
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Should NOT use SNOWFLAKE_ACCOUNT env var
  args <- snowflake_args(driver = "driver")
  expect_equal(args$account, "configaccount")

  # SHOULD use SNOWFLAKE_ACCOUNT env var as fallback
  args2 <- snowflake_args(driver = "driver", uid = "user", pwd = "password")
  expect_equal(args2$account, "envaccount")
})

test_that("Invalid connection_name errors with known names", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c('[prod]', 'account = "test"', '', '[dev]', 'account = "test"'),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  expect_snapshot(
    snowflake_args(connection_name = "staging", driver = "driver"),
    error = TRUE
  )
})

test_that("Missing default connection errors with known names", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  writeLines(
    c('[prod]', 'account = "test"', 'user = "test"', 'password = "test"'),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SNOWFLAKE_ACCOUNT = "",
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  expect_snapshot(
    snowflake_args(driver = "driver"),
    error = TRUE
  )
})

test_that("map_param_names() correctly maps user/password to uid/pwd", {
  params <- list(
    account = "test",
    user = "myuser",
    password = "mypassword",
    warehouse = "WH"
  )

  mapped <- map_param_names(params)

  expect_equal(mapped$uid, "myuser")
  expect_equal(mapped$pwd, "mypassword")
  expect_null(mapped$user)
  expect_null(mapped$password)
  expect_equal(mapped$account, "test")
  expect_equal(mapped$warehouse, "WH")
})

test_that("connections_file_path overrides default location", {
  skip_if_not_installed("toml")

  custom_file <- tempfile(fileext = ".toml")
  writeLines(
    c(
      '[custom]',
      'account = "customaccount"',
      'user = "customuser"',
      'password = "custompwd"'
    ),
    custom_file
  )
  withr::defer(unlink(custom_file))

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true")

  args <- snowflake_args(
    connection_name = "custom",
    connections_file_path = custom_file,
    driver = "driver"
  )

  expect_equal(args$account, "customaccount")
  expect_equal(args$uid, "customuser")
})

test_that("check_toml_file_permissions() is skipped on Windows", {
  skip_on_os(c("mac", "linux"))
  # Should not error on Windows regardless of permissions
  expect_silent(check_toml_file_permissions("/any/path"))
})

test_that("check_toml_file_permissions() can be bypassed with env var", {
  skip_on_os("windows")

  withr::local_envvar(
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Should not warn even if file has bad permissions
  expect_silent(check_toml_file_permissions("/any/path"))
})

test_that("check_toml_file_permissions() errors on group/other writable files", {
  skip_on_os("windows")
  skip_if_not_installed("toml")

  config_file <- tempfile()
  writeLines('[default]\naccount = "test"', config_file)
  withr::defer(unlink(config_file))

  # Make writable by group (need to use system chmod to bypass umask)
  system2("chmod", c("0620", config_file))

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "")

  expect_error(
    check_toml_file_permissions(config_file),
    "writable by group or others"
  )
})

test_that("check_toml_file_permissions() warns on other-readable files", {
  skip_on_os("windows")
  skip_if_not_installed("toml")

  config_file <- tempfile()
  writeLines('[default]\naccount = "test"', config_file)
  withr::defer(unlink(config_file))

  # Make readable by others but not writable
  Sys.chmod(config_file, mode = "0644")

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "")

  expect_warning(
    check_toml_file_permissions(config_file),
    "Bad owner or permissions"
  )
})

test_that("check_toml_file_permissions() passes with correct permissions (0600)", {
  skip_on_os("windows")
  skip_if_not_installed("toml")

  config_file <- tempfile()
  writeLines('[default]\naccount = "test"', config_file)
  withr::defer(unlink(config_file))

  # Set correct permissions
  Sys.chmod(config_file, mode = "0600")

  withr::local_envvar(SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "")

  expect_no_error(check_toml_file_permissions(config_file))
  expect_no_warning(check_toml_file_permissions(config_file))
})

test_that("SNOWFLAKE_CONNECTIONS can use default_connection_name from config.toml", {
  skip_if_not_installed("toml")

  config_dir <- withr::local_tempdir()

  # config.toml sets default_connection_name to "myconn"
  writeLines(
    'default_connection_name = "myconn"',
    file.path(config_dir, "config.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    # SNOWFLAKE_CONNECTIONS provides the connections (overrides files)
    SNOWFLAKE_CONNECTIONS = '[myconn]\naccount = "envaccount"\nuser = "envuser"\npassword = "envpwd"',
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Should use default_connection_name from config.toml with connections from env var
  args <- snowflake_args(driver = "driver")

  expect_equal(args$account, "envaccount")
  expect_equal(args$uid, "envuser")
})

test_that("Missing toml errors when config files exist (Case 2)", {
  config_dir <- withr::local_tempdir()

  # Create a connections.toml file
  writeLines(
    c('[default]', 'account = "test"', 'user = "user"', 'password = "pwd"'),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Mock toml as not installed
  local_mocked_bindings(
    check_toml_installed = function() {
      rlang::abort("The toml package is required to load Snowflake configuration files.")
    }
  )

  # No programmatic params, should try to load config and error
  expect_error(
    snowflake_args(driver = "driver"),
    "toml.*required"
  )
})

test_that("Missing toml errors when SNOWFLAKE_CONNECTIONS is set", {
  withr::local_envvar(
    SNOWFLAKE_CONNECTIONS = '[default]\naccount = "test"',
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Mock toml as not installed
  local_mocked_bindings(
    check_toml_installed = function() {
      rlang::abort("The toml package is required to load Snowflake configuration files.")
    }
  )

  # Should error because we need toml to parse SNOWFLAKE_CONNECTIONS
  expect_error(
    snowflake_args(driver = "driver"),
    "toml.*required"
  )
})

test_that("Missing toml does NOT error when programmatic params provided (Case 3)", {
  config_dir <- withr::local_tempdir()

  # Create a connections.toml file (should be ignored in Case 3)
  writeLines(
    c('[default]', 'account = "fileaccount"', 'user = "fileuser"', 'password = "filepwd"'),
    file.path(config_dir, "connections.toml")
  )

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Mock toml as not installed - should not matter because we have programmatic params
  local_mocked_bindings(
    check_toml_installed = function() {
      rlang::abort("The toml package is required to load Snowflake configuration files.")
    }
  )

  # Has programmatic params, should NOT try to load config
  args <- snowflake_args(
    account = "programmatic",
    driver = "driver",
    uid = "user",
    pwd = "password"
  )

  expect_equal(args$account, "programmatic")
  expect_equal(args$uid, "user")
})

test_that("Missing toml does NOT error when no config files and no env var", {
  config_dir <- withr::local_tempdir()

  # Empty config dir - no toml files

  withr::local_envvar(
    SNOWFLAKE_HOME = config_dir,
    SNOWFLAKE_CONNECTIONS = "",
    SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE = "true"
  )

  # Mock toml as not installed
  local_mocked_bindings(
    is_installed = function(pkg) pkg != "toml",
    .package = "rlang"
  )

  # Should error about missing credentials, not about missing toml
  expect_error(
    snowflake_args(driver = "driver"),
    "cannot be found"
  )
})
