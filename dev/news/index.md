# Changelog

## odbc (development version)

- odbcConnectionColumns(), odbcConnectionIcon(), and
  odbcConnectionActions() are now fully deprecated. Use
  DBI::dbListFields() instead of odbcConnectionColumns()
  ([\#699](https://github.com/r-dbi/odbc/issues/699)). \# odbc 1.6.4

- Fix writing of \[R\] date/time values that have integer storage.
  ([\#952](https://github.com/r-dbi/odbc/issues/952))

- Oracle: Fix writing values to `DATE` targets.
  ([\#959](https://github.com/r-dbi/odbc/issues/959))

- SQL Server: Fix time zone interpretation in `DATETIMEOFFSET` data; now
  follows ISO 8061 convention where positive offset denotes time zone
  east of Greenwich. ([\#946](https://github.com/r-dbi/odbc/issues/946))

## odbc 1.6.3

CRAN release: 2025-09-05

- Addressed a compiler warning on `r-devel-linux-x86_64-fedora-clang`
  ([\#941](https://github.com/r-dbi/odbc/issues/941)).

## odbc 1.6.2

CRAN release: 2025-08-28

- Fix hang when parsing exceptionally long database errors
  ([\#916](https://github.com/r-dbi/odbc/issues/916)).

- Fix retrieving multiple result sets from parametrized queries in cases
  when some parameters yield empty results
  ([\#927](https://github.com/r-dbi/odbc/issues/927)).

- Databricks and Snowflake:

  - The package will prefer shlib to locate statically built
    installations of unixodbc, correcting an issue with erroneously
    overwritten lines in `simba.sparkodbc.ini`
    ([\#921](https://github.com/r-dbi/odbc/issues/921)).
  - [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
    no longer errors on repeated calls
    ([\#901](https://github.com/r-dbi/odbc/issues/901)).

- DB2:

  - `DB2_XML` support added
    ([\#913](https://github.com/r-dbi/odbc/issues/913)).
  - Fix error when writing to temp tables
    ([\#910](https://github.com/r-dbi/odbc/issues/910)).

- Snowflake:

  - `sf_private_key` and `sf_private_key_password` connection attributes
    added to pass PEM formatted private key contents directly from
    memory ([\#933](https://github.com/r-dbi/odbc/issues/933)).
  - Corrected search paths for `.ini` files, so the package is now more
    likely to find configuration files by default
    ([\#937](https://github.com/r-dbi/odbc/issues/937)).

- SQL Server:

  - Fix issues with argument propagation in bespoke S4 methods
    ([\#906](https://github.com/r-dbi/odbc/issues/906)).
  - `DATETIMEOFFSET` data type support added
    ([\#918](https://github.com/r-dbi/odbc/issues/918)).
  - `data.frames` can now bind to table valued parameters of stored
    procedures ([\#928](https://github.com/r-dbi/odbc/issues/928)).

## odbc 1.6.1

CRAN release: 2025-03-27

- odbc will now automatically find statically built installations of
  unixodbc ([\#899](https://github.com/r-dbi/odbc/issues/899)).

## odbc 1.6.0

CRAN release: 2025-02-28

### New features

- A hex logo has been added to the package
  ([@edgararuiz](https://github.com/edgararuiz),
  [\#824](https://github.com/r-dbi/odbc/issues/824)).

- [`databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  and [`snowflake()`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  detect viewer-based credentials on Posit Connect
  ([@atheriel](https://github.com/atheriel),
  [\#853](https://github.com/r-dbi/odbc/issues/853) and
  [\#894](https://github.com/r-dbi/odbc/issues/894)).

- [`odbcEditDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md),
  [`odbcEditSystemDSN()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md),
  and
  [`odbcEditUserDSN()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  create shortcuts for `file.edit(odbcListConfig()[[i]])` on macOS and
  Linux ([@simonpcouch](https://github.com/simonpcouch),
  [\#827](https://github.com/r-dbi/odbc/issues/827)).

- New [`redshift()`](https://odbc.r-dbi.org/dev/reference/redshift.md)
  helper simplifies connections to Amazon Redshift clusters,
  particularly with IAM credentials
  ([@atheriel](https://github.com/atheriel),
  [\#879](https://github.com/r-dbi/odbc/issues/879)).

### Bug fixes and minor improvements

- Error messages rethrown from drivers no longer become garbled when raw
  messages contain curly brackets
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#859](https://github.com/r-dbi/odbc/issues/859)).

- SQL Server drivers installed with homebrew are now discovered
  automatically on ARM macOS
  ([@stevecondylios](https://github.com/stevecondylios),
  [\#893](https://github.com/r-dbi/odbc/issues/893)).

- `databricks(workspace)` removes trailing slashes automatically,
  preventing uninformative driver messages
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#827](https://github.com/r-dbi/odbc/issues/827)).

- [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  displays clear errors when unixODBC isn’t found on macOS and Linux
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#782](https://github.com/r-dbi/odbc/issues/782)).

- [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  adds `name_encoding` to complement `encoding` for separate column
  content and name encoding
  ([\#845](https://github.com/r-dbi/odbc/issues/845)).

- [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
  and
  [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
  improve temp table support with DB2
  ([\#823](https://github.com/r-dbi/odbc/issues/823)).

- Netezza character and boolean columns receive improved data type
  inference ([\#847](https://github.com/r-dbi/odbc/issues/847),
  [\#850](https://github.com/r-dbi/odbc/issues/850)).

- Oracle `DATE` and `TIMESTAMP(n)` targets handle writes correctly with
  `batch_size > 1` ([\#810](https://github.com/r-dbi/odbc/issues/810)).

- [`snowflake()`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  checks runtime driver configuration on macOS
  ([\#857](https://github.com/r-dbi/odbc/issues/857)).

- [`snowflake()`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  accepts `uid` without `pwd` when using
  `authenticator = "externalbrowser"` or
  `authenticator = "SNOWFLAKE_JWT"`
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#817](https://github.com/r-dbi/odbc/issues/817) and
  [\#889](https://github.com/r-dbi/odbc/issues/889)).

- Resolved SQL Server data truncation in temp tables with `FreeTDS`
  ([\#866](https://github.com/r-dbi/odbc/issues/866)), writing issues
  with SIMBA drivers
  ([\#816](https://github.com/r-dbi/odbc/issues/816)), `hms` data
  roundtrip ([\#887](https://github.com/r-dbi/odbc/issues/887)), and
  precision when writing to `DATETIME2` targets
  ([\#793](https://github.com/r-dbi/odbc/issues/793)).

## odbc 1.5.0

CRAN release: 2024-06-05

### Major changes

- New function
  [`snowflake()`](https://odbc.r-dbi.org/dev/reference/snowflake.md)
  makes it easier to connect to Snowflake, automatically handling
  authentication correctly on platforms that provide Snowflake-native
  OAuth credentials ([@atheriel](https://github.com/atheriel),
  [\#662](https://github.com/r-dbi/odbc/issues/662)).

- Long running queries can now be interrupted using Ctrl-C. This feature
  is enabled by default in interactive sessions. It can be controlled by
  the `interruptible` argument to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  or by the global option `odbc.interruptible`. Should be considered
  experimental—if you experience problems please file an issue on the
  package’s GitHub repository
  ([\#796](https://github.com/r-dbi/odbc/issues/796)).

### Minor improvements and bug fixes

- Improved argument checking and transitioned to the cli package for
  formatting most existing error messages
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#781](https://github.com/r-dbi/odbc/issues/781),
  [\#784](https://github.com/r-dbi/odbc/issues/784),
  [\#785](https://github.com/r-dbi/odbc/issues/785),
  [\#788](https://github.com/r-dbi/odbc/issues/788)).

- Raises “Cancelling previous query” warnings from R rather than from
  Rcpp when a connection has a current result to avoid possible
  incorrect resource unwinds with `options(warn = 2)`
  ([\#797](https://github.com/r-dbi/odbc/issues/797)).

- Adjusted the default `batch_rows` value for
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) methods.
  odbc 1.3.0 changed the default value from 1024 to `NA`, which sets the
  batch size to be the length of the input. While this addressed issues
  for some drivers when 1024 was greater than the number of rows, it
  also led to excessive memory consumption when the input was very large
  for some other drivers. The package will now interpet `NA` as the
  minimum of 1024 and the length of the input
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#774](https://github.com/r-dbi/odbc/issues/774)).

- The encoding of non-ASCII column names of SQL results is now always
  converted to UTF-8. ([@shrektan](https://github.com/shrektan),
  [\#430](https://github.com/r-dbi/odbc/issues/430))

- Improved error messages when the encoding of client and db-server are
  different. ([@shrektan](https://github.com/shrektan),
  [\#432](https://github.com/r-dbi/odbc/issues/432))

- [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
  now works with [`Id()`](https://dbi.r-dbi.org/reference/Id.html) and
  [`SQL()`](https://dbi.r-dbi.org/reference/SQL.html) identifiers
  ([\#771](https://github.com/r-dbi/odbc/issues/771)).

- Transitioned
  [`odbcDataType()`](https://odbc.r-dbi.org/dev/reference/odbcDataType.md)
  to use S4 for consistency. S3 methods defined locally will need to be
  rewritten ([@simonpcouch](https://github.com/simonpcouch),
  [\#701](https://github.com/r-dbi/odbc/issues/701)).

- The `"OdbcConnection"` method for
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  will no longer pass `x` to
  [`encodeString()`](https://rdrr.io/r/base/encodeString.html) before
  returning, for consistency with the default implementation in DBI
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#765](https://github.com/r-dbi/odbc/issues/765)).

- A bug in the implementation of a new feature introduced in 1.4.2,
  where the package would automatically set the `ODBCSYSINI`
  environmental variable when using the unixODBC driver manager, was
  fixed; that environmental variable will now actually be set on package
  load ([@simonpcouch](https://github.com/simonpcouch),
  [\#792](https://github.com/r-dbi/odbc/issues/792)).

### Driver specific changes

- [`databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  will now automatically configure the needed driver and driver manager
  on macOS ([@simonpcouch](https://github.com/simonpcouch),
  [\#651](https://github.com/r-dbi/odbc/issues/651)).

- [`databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  now picks up on Posit Workbench-managed Databricks credentials when
  rendering Quarto and RMarkdown documents in RStudio
  ([@atheriel](https://github.com/atheriel),
  [\#805](https://github.com/r-dbi/odbc/issues/805)).

- Improved performance on write with Snowflake
  ([\#760](https://github.com/r-dbi/odbc/issues/760)).

- Resolved issue when previewing tables using the RStudio Connections
  pane with Teradata ([@simonpcouch](https://github.com/simonpcouch),
  [\#755](https://github.com/r-dbi/odbc/issues/755)).

## odbc 1.4.2

CRAN release: 2024-01-22

- [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  Improve performance by checking existence once
  ([\#691](https://github.com/r-dbi/odbc/issues/691)).

- [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  no longer automatically escapes suspicious characters (since there
  doesn’t seem to be a consistent way to do this across drivers) but
  instead points you to
  [`quote_value()`](https://odbc.r-dbi.org/dev/reference/quote_value.md)
  which applies a heuristic that should work for most drivers
  ([\#718](https://github.com/r-dbi/odbc/issues/718)).

- New wrapper for
  [`dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html) that
  sets `immediate = TRUE` if you are not supplying `params`. That should
  yield a small speed boost in many cases
  ([\#706](https://github.com/r-dbi/odbc/issues/706)).

- [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  once again defaults to `immediate = FALSE` (since if you’re using it
  instead of
  [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html)
  you’re likely to be using it with
  [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html)).
  ([\#726](https://github.com/r-dbi/odbc/issues/726)).

- Deprecated
  [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)
  (in favor of
  [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)),
  [`odbcConnectionActions()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionActions.md),
  and
  [`odbcConnectionIcon()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionIcon.md)
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#699](https://github.com/r-dbi/odbc/issues/699)).

- Backend specific changes:

  - databricks: Fix schema enumeration in connections pane
    ([@detule](https://github.com/detule),
    [\#715](https://github.com/r-dbi/odbc/issues/715)).

  - Oracle: use more reliable technique to determine user/schema name
    ([\#738](https://github.com/r-dbi/odbc/issues/738)), and fix
    [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
    when identifier components contain `_`
    ([@detule](https://github.com/detule),
    [\#712](https://github.com/r-dbi/odbc/issues/712)).

  - SQL Server: improvements to `dbExists()`
    ([@meztez](https://github.com/meztez),
    [\#724](https://github.com/r-dbi/odbc/issues/724)) and
    [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
    ([@simonpcouch](https://github.com/simonpcouch),
    [\#509](https://github.com/r-dbi/odbc/issues/509)) for temporary
    tables. It now uses column type `"BIGINT"` integer64 objects.

  - SQL Server with freetds driver: no longer crashes when executing
    multiple queries ([@detule](https://github.com/detule),
    [\#731](https://github.com/r-dbi/odbc/issues/731)).

  - Teradata: Fix usage of `exact` argument in internal methods
    ([@detule](https://github.com/detule), 717).

- On MacOS and Linux, the package will now automatically set the
  `ODBCSYSINI` environmental variable when using the unixODBC driver
  manager. `ODBCSYSINI` will not be changed if it exists already
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#709](https://github.com/r-dbi/odbc/issues/709)).

## odbc 1.4.1

CRAN release: 2023-12-21

- New
  [`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
  lists configuration files on Mac and Linux
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#565](https://github.com/r-dbi/odbc/issues/565)).

- [`databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  now works with manually supplied `pwd` and `uid`
  ([\#690](https://github.com/r-dbi/odbc/issues/690)).

- Oracle: uses correct parent class
  ([\#685](https://github.com/r-dbi/odbc/issues/685)).

- SQL Server: correctly enumerate schemas across databases in
  connections pane ([@detule](https://github.com/detule),
  [\#527](https://github.com/r-dbi/odbc/issues/527)).

## odbc 1.4.0

CRAN release: 2023-12-15

### Major changes

- New
  [`odbc::databricks()`](https://odbc.r-dbi.org/dev/reference/databricks.md)
  makes it easier to connect to Databricks, automatically handling many
  common authentication scenarios
  ([@atheriel](https://github.com/atheriel),
  [\#615](https://github.com/r-dbi/odbc/issues/615)).

- [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html),
  [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
  and
  [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
  automatically escape underscores in identifier arguments. This leads
  to substantial performance improvements for some backends
  (e.g. snowflake) ([@detule](https://github.com/detule),
  [@fh-afrachioni](https://github.com/fh-afrachioni),
  [\#618](https://github.com/r-dbi/odbc/issues/618)).

- [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html) and
  [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  now set `immediate = TRUE` if you are not using a parameterised query.
  That should yield a small speed boost in many cases
  ([\#633](https://github.com/r-dbi/odbc/issues/633)).

### Minor improvements and bug fixes

- Increased the minimum required R version from 3.2.0 to 3.6.0
  ([@simonpcouch](https://github.com/simonpcouch),
  [\#629](https://github.com/r-dbi/odbc/issues/629)).

- S4 classes for the most database drivers are now exported, make it
  possible to use in other packages
  ([\#558](https://github.com/r-dbi/odbc/issues/558)).

- ODBC errors are now spread across multiple lines, making them easier
  to read ([@detule](https://github.com/detule),
  [\#564](https://github.com/r-dbi/odbc/issues/564)).

- `DBI::dbConnect(odbc::odbc())` now gives a clear error if you supply
  multiple arguments with the same name when case is ignored
  ([\#641](https://github.com/r-dbi/odbc/issues/641)).

- `DBI::dbConnect(odbc::odbc())` now automatically quotes argument
  values that need it
  ([\#616](https://github.com/r-dbi/odbc/issues/616)).

### Driver specific changes

- Oracle: Fix regression when falling back to
  [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)
  to describe column data types ([@detule](https://github.com/detule),
  [\#587](https://github.com/r-dbi/odbc/issues/587))

- Spark SQL: Correctly enumerate schemas away from the current catalog
  ([@detule](https://github.com/detule),
  [\#614](https://github.com/r-dbi/odbc/issues/614))

- Snowflake: improved translation from R to snowflake types
  ([@meztez](https://github.com/meztez),
  [\#599](https://github.com/r-dbi/odbc/issues/599)).

- SQL Server

  - Improved handling for local temp tables in `dbWrite()`,
    [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html),
    and `dbExistTable()` ([@detule](https://github.com/detule),
    [\#600](https://github.com/r-dbi/odbc/issues/600))

  - Specialize syntax in `sqlCreateTable` to avoid failures when writing
    to (new) local temp tables. ([@detule](https://github.com/detule),
    [\#601](https://github.com/r-dbi/odbc/issues/601))

- Teradata: Improved handling for temp tables
  ([@detule](https://github.com/detule) and
  [@But2ene](https://github.com/But2ene),
  [\#589](https://github.com/r-dbi/odbc/issues/589), 590)

## odbc 1.3.5

CRAN release: 2023-06-29

- Various fixes for `R CMD check`.

- The argument order for
  [`sqlCreateTable()`](https://dbi.r-dbi.org/reference/sqlCreateTable.html)
  methods avoiding weird argument mismatch problems
  ([\#448](https://github.com/r-dbi/odbc/issues/448)).

- Fixed truncation when retrieving unicode data stored in VAR/CHAR
  columns ([@detule](https://github.com/detule),
  [\#553](https://github.com/r-dbi/odbc/issues/553)).

- Fixed issue related to fetching zero rows
  ([@detule](https://github.com/detule),
  [\#528](https://github.com/r-dbi/odbc/issues/528)).

- Backend specific improvements:

  - MYSQL: Fixed retrieving results from stored procedures
    ([@detule](https://github.com/detule),
    [\#435](https://github.com/r-dbi/odbc/issues/435)).
  - Oracle: performance enhancements
    ([\#577](https://github.com/r-dbi/odbc/issues/577))
  - Spark: Changed data type for date-times from `DATE` to `TIMESTAMP`
    ([@schuemie](https://github.com/schuemie),
    [\#555](https://github.com/r-dbi/odbc/issues/555)).

## odbc 1.3.4

CRAN release: 2023-01-17

- Optimized table preview methods. Enhances large table preview within
  RStudio IDE ([@detule](https://github.com/detule),
  [\#525](https://github.com/r-dbi/odbc/issues/525)).

- Added `attributes` parameter to `dbConnect(...)`. Can be used to pass
  a token and authenticate against Azure AD when using Microsoft SQL
  Server. Documented in
  [`?ConnectionAttributes`](https://odbc.r-dbi.org/dev/reference/ConnectionAttributes.md)
  ([@detule](https://github.com/detule),
  [\#521](https://github.com/r-dbi/odbc/issues/521)).

- Fix `length(x) = 3 > 1' in coercion to 'logical(1)` warning in
  connection observer ([@meztez](https://github.com/meztez),
  [\#494](https://github.com/r-dbi/odbc/issues/494)).

## odbc 1.3.3

CRAN release: 2021-11-30

- Hadley Wickham is now the maintainer.

## odbc 1.3.2

CRAN release: 2021-04-03

- New `odbcDataType.Snowflake()` method for Snowflake databases.
  ([@edgararuiz](https://github.com/edgararuiz),
  [\#451](https://github.com/r-dbi/odbc/issues/451))

## odbc 1.3.1

CRAN release: 2021-03-16

- Fixed warnings about anonymous unions
  ([@detule](https://github.com/detule),
  [\#440](https://github.com/r-dbi/odbc/issues/440))
- Fixed `invalid descriptor` issues when retrieving results from SQL
  Server + Microsoft’s ODBC driver, using parametrized queries.
  ([@detule](https://github.com/detule),
  [\#414](https://github.com/r-dbi/odbc/issues/414))
- Fixed null handling in SQL Server / Azure result sets retrieved with
  Microsoft’s ODBC driver. ([@detule](https://github.com/detule),
  [\#408](https://github.com/r-dbi/odbc/issues/408))
- Hive uses C-style escaping for string literals (single quotes are
  backslash-escaped, note single quote-escaped). `dbQuoteString` now
  respects this when called on a connection of class `Hive`.
  ([@rnorberg](https://github.com/rnorberg),
  [\#184](https://github.com/r-dbi/odbc/issues/184))
- When calling `sqlCreateTable(con, ..., temporary = TRUE)` and `con` is
  a connection of class `DB2/AIX64`, the `CREATE TABLE` statement that
  is generated properly creates a temporary table in DB2. The statement
  begins with `DECLARE GLOBAL TEMPORARY TABLE` at
  `https://www.ibm.com/docs/SSEPEK_11.0.0/sqlref/src/tpc/db2z_sql_declareglobaltemptable.html`
  and ends with `ON COMMIT PRESERVE ROWS` (DB2’s default behavior is
  `ON COMMIT DELETE ROWS`, which results in the inserted data being
  deleted as soon as `dbWriteTable` completes).
  ([@rnorberg](https://github.com/rnorberg),
  [\#426](https://github.com/r-dbi/odbc/issues/426))
- Fixed RStudio Connections Pane when working with a database that has
  only one catalog or one schema. ([@meztez](https://github.com/meztez),
  [\#444](https://github.com/r-dbi/odbc/issues/444))

## odbc 1.3.0

CRAN release: 2020-10-27

### Major changes

- odbc can now be compiled again with Rtools35 (gcc 4.9.3) on Windows
  ([\#383](https://github.com/r-dbi/odbc/issues/383))
- `invalid descriptor` errors from drivers such as Microsoft SQLServer
  driver and the freeTDS driver which do not support out of order
  retrieval are now avoided. This is done by unbinding any nanodbc
  buffer past the long column. Performance for the unbound columns in
  these cases will be reduced, but the retrieval will work without error
  ([@detule](https://github.com/detule),
  [\#381](https://github.com/r-dbi/odbc/issues/381))
- [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) and
  [`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) now
  support multiple result sets
  ([@vkapartzianis](https://github.com/vkapartzianis),
  [\#345](https://github.com/r-dbi/odbc/issues/345))

### Minor improvements and fixes

- New
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  method for OdbcConnection objects
  ([\#335](https://github.com/r-dbi/odbc/issues/335))
- [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  now uses the input names (if any).
- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) now
  default to a `batch_rows` of `NA`, which sets the batch size to be the
  length of the input. This avoids problems with drivers that don’t
  support batch sizes larger than the input size. To restore the
  behavior prior to this release pass `batch_rows = 1024` or set
  `options(odbc.batch_rows = 1024)`
  ([\#391](https://github.com/r-dbi/odbc/issues/391)).
- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  now handles `data.table::IDate()` objects
  ([\#388](https://github.com/r-dbi/odbc/issues/388))
- `dbWriteTable(field.types=)` now issues a warning rather than an error
  for missing columns
  ([\#342](https://github.com/r-dbi/odbc/issues/342))
- [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)
  now works as intended with
  [`DBI::Id()`](https://dbi.r-dbi.org/reference/Id.html) objects
  ([\#389](https://github.com/r-dbi/odbc/issues/389))
- [`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) now
  verifies that `n` is a valid input.
- Dates are now always interpreted as being in the database’s local time
  zone, regardless of the `timezone` parameter
  ([\#398](https://github.com/r-dbi/odbc/issues/398))
- Oracle connections now support `Date` and `POSIXct` types via `DATE`
  and `TIMESTAMP` data types
  ([\#324](https://github.com/r-dbi/odbc/issues/324),
  [\#349](https://github.com/r-dbi/odbc/issues/349),
  [\#350](https://github.com/r-dbi/odbc/issues/350))
- Oracle connections now use VARCHAR2 rather than VARCHAR, as
  recommended by Oracle’s documentation
  ([\#189](https://github.com/r-dbi/odbc/issues/189))

## odbc 1.2.3

CRAN release: 2020-06-18

- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  now executes immediately, which fixes issues with temporary tables and
  the FreeTDS SQL Server driver ([@krlmlr](https://github.com/krlmlr)).

- blob roundtrips now work in more cases
  ([\#364](https://github.com/r-dbi/odbc/issues/364),
  [@krlmlr](https://github.com/krlmlr)).

- The BH dependency has been removed
  ([\#326](https://github.com/r-dbi/odbc/issues/326))

## odbc 1.2.2

CRAN release: 2020-01-10

- The configure script now again uses iodbc-config on macOS, if
  available.

- Fix errors with drivers who do not fully implement SQLGetInfo
  ([\#325](https://github.com/r-dbi/odbc/issues/325)).

## odbc 1.2.1

CRAN release: 2019-12-05

- Fix the unicode character width issues with the macOS odbc CRAN
  binary. ([\#283](https://github.com/r-dbi/odbc/issues/283))

- The configure script now works on systems whose /bin/sh does not
  support command substitution, such as Solaris 10.

## odbc 1.2.0

CRAN release: 2019-11-28

### Features

- [`sqlCreateTable()`](https://dbi.r-dbi.org/reference/sqlCreateTable.html)
  and
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  now throw an error if you mistakenly include `field.types` names which
  do not exist in the input data.
  ([\#271](https://github.com/r-dbi/odbc/issues/271))

- The error message when trying to write tables with unsupported types
  now includes the column name
  ([\#238](https://github.com/r-dbi/odbc/issues/238)).

- [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  now has a new param `timezone_out` which is useful if the user wants
  the datetime values be marked with a specific timezone instead of UTC
  ([@shrektan](https://github.com/shrektan),
  [\#294](https://github.com/r-dbi/odbc/issues/294)).

- [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html),
  [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  and
  [`dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html)
  gain a `immediate` argument to execute the statement or query
  immediately instead of preparing, then executing the statement.
  ([\#272](https://github.com/r-dbi/odbc/issues/272),
  [@krlmlr](https://github.com/krlmlr))

- [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html),
  [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  and
  [`dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html)
  gain a `params` argument, which allows them to be used (indirectly) by
  [`DBI::dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  ([\#210](https://github.com/r-dbi/odbc/issues/210),
  [\#215](https://github.com/r-dbi/odbc/issues/215),
  [\#261](https://github.com/r-dbi/odbc/issues/261)).

- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) methods
  gain a `batch_rows` argument, to control how many rows are bound in
  each batch. The default can be set globally with
  `options(odbc.batch_rows)`. This is useful if your database performs
  better with a larger or smaller number of rows per batch than the
  default of 1024. ([\#297](https://github.com/r-dbi/odbc/issues/297))

- New
  [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)
  function to describe the column types. This data is used when binding
  columns, which allows drivers which do not support the
  `SQLDescribeParam()` ODBC function, such as freeTDS to work better
  with bound columns.
  ([\#313](https://github.com/r-dbi/odbc/issues/313),
  [@detule](https://github.com/detule))

- Added a Teradata
  [`odbcDataType()`](https://odbc.r-dbi.org/dev/reference/odbcDataType.md)
  to support writing logical data to Teradata servers
  ([\#240](https://github.com/r-dbi/odbc/issues/240),
  [@blarj09](https://github.com/blarj09)).

- Added a Access
  [`odbcDataType()`](https://odbc.r-dbi.org/dev/reference/odbcDataType.md)
  method to support writing to Access databases
  ([\#262](https://github.com/r-dbi/odbc/issues/262),
  [@vh-d](https://github.com/vh-d))

- [`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
  gains a `keep` and `filter` argument and global options
  `odbc.drivers_keep`, `odbc.drivers_filter` to keep and filter the
  drivers returned. This is useful if system administrators want to
  reduce the number of drivers shown to users.
  ([@blairj09](https://github.com/blairj09),
  [\#274](https://github.com/r-dbi/odbc/issues/274))

- Subseconds are now retained when inserting POSIXct objects
  ([\#130](https://github.com/r-dbi/odbc/issues/130),
  [\#208](https://github.com/r-dbi/odbc/issues/208))

- The RStudio Connections Pane now shows the DSN, when available
  ([\#304](https://github.com/r-dbi/odbc/issues/304),
  [@davidchall](https://github.com/davidchall)).

### Bugfixes

- SQL Server ODBC’s now supports the ‘-155’ data type, and its losing
  sub-second precision on timestamps; this still returns type
  `DATETIMEOFFSET` as a character, but it preserves sub-seconds and has
  a numeric timezone offset ([@r2evans](https://github.com/r2evans),
  [\#207](https://github.com/r-dbi/odbc/issues/207)).

- [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
  now handles the case-sensitivity consistently as other methods
  ([@shrektan](https://github.com/shrektan),
  [\#285](https://github.com/r-dbi/odbc/issues/285)).

- [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
  now works for SQL Server when specifying schemas but not catalogs
  using the freeTDS and Simba drivers.
  ([\#197](https://github.com/r-dbi/odbc/issues/197))

- [`DBI::dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
  no longer fails when used with a a qualified Id object (using both
  schema and table) ([\#226](https://github.com/r-dbi/odbc/issues/226)).

- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  now always writes `NA_character` as `NULL` for data.frame with only
  one row ([@shrektan](https://github.com/shrektan),
  [\#288](https://github.com/r-dbi/odbc/issues/288)).

- Fix an issue that the date value fetched from the database may be one
  day before its real value ([@shrektan](https://github.com/shrektan),
  [\#295](https://github.com/r-dbi/odbc/issues/295)).

## odbc 1.1.6

CRAN release: 2018-06-09

### Features

- [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  gains a `timeout` parameter, to control how long a connection should
  be attempted before timing out
  ([\#139](https://github.com/r-dbi/odbc/issues/139)).

- Full schema support using Id objects available in DBI 0.8
  ([\#91](https://github.com/r-dbi/odbc/issues/91),
  [\#120](https://github.com/r-dbi/odbc/issues/120)).

### Bugfixes

- SQL inputs are always converted to database encoding before querying
  ([\#179](https://github.com/r-dbi/odbc/issues/179)).

## odbc 1.1.5

CRAN release: 2018-01-23

- Fix the return value for
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  when given a length 0 input
  ([\#146](https://github.com/r-dbi/odbc/issues/146)
  [@edgararuiz](https://github.com/edgararuiz)).

## odbc 1.1.4

CRAN release: 2018-01-10

### Features

- Add custom `sqlCreateTable` and `dbListTables` method for Teradata
  connections ([\#121](https://github.com/r-dbi/odbc/issues/121),
  [@edgararuiz](https://github.com/edgararuiz)).

- Add `dbms.name` parameter to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  to allow the user to set the database management system name in cases
  it cannot be queried from the Driver
  ([\#115](https://github.com/r-dbi/odbc/issues/115),
  [@hoxo-m](https://github.com/hoxo-m)).

### Bugfixes

- Fix multiple transactions with rollback
  ([\#136](https://github.com/r-dbi/odbc/issues/136)).

- Fix translation of missing values for integer types
  ([\#119](https://github.com/r-dbi/odbc/issues/119)).

- Update PIC flags to avoid portability concerns.

## odbc 1.1.3

CRAN release: 2017-10-05

- Small patch to fix install errors on CRAN’s MacOS machines.

## odbc 1.1.2

CRAN release: 2017-10-02

- Add `bigint` parameter to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  to allow the user to set the behavior when converting 64 bit integers
  into R types.

- Fixes for compatibility with the RStudio Connections pane and viewer.
  ([@jmcphers](https://github.com/jmcphers)).

- Define `BUILD_REAL_64_BIT_MODE` for compatibility with older systems
  `sql.h`, to ensure we always use 8 byte pointers.

- Added temporary-table support for Oracle database using a custom
  `sqlCreateTable` ([\#99](https://github.com/r-dbi/odbc/issues/99),
  [@edgararuiz](https://github.com/edgararuiz)).

- Fix regression when binding due to the num_columns variable not being
  updated by `odbc_result::bind_list()`.

- Support table creation for Vertica and Redshift
  ([\#93](https://github.com/r-dbi/odbc/issues/93),
  [@khotilov](https://github.com/khotilov)).

- Changed parameter `fieldTypes` to `field.types` in functions
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and
  [`sqlCreateTable()`](https://dbi.r-dbi.org/reference/sqlCreateTable.html)
  to be compliant with DBI
  ([\#106](https://github.com/r-dbi/odbc/issues/106),
  [@jschelbert](https://github.com/jschelbert)).

- dbSendStatement no longer executes the statement, this is instead done
  when [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) or
  [`dbGetRowsAffected()`](https://dbi.r-dbi.org/reference/dbGetRowsAffected.html)
  is called. This change brings ODBC into compliance with the DBI
  specification for
  [`dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html)
  ([\#84](https://github.com/r-dbi/odbc/issues/84),
  [@ruiyiz](https://github.com/ruiyiz)).

## odbc 1.1.1

CRAN release: 2017-06-27

- Workaround for drivers which do not implement SQLGetInfo, such as the
  Access driver ([\#78](https://github.com/r-dbi/odbc/issues/78)).

- Fix for installation error for systems without GNU Make as the default
  make, such as Solaris.

## odbc 1.1.0

CRAN release: 2017-06-23

- Provide a fall backs for drivers which do not support
  `SQLDescribeParam` and those which do not support transactions.

- [`sqlCreateTable()`](https://dbi.r-dbi.org/reference/sqlCreateTable.html)
  gains a `fieldTypes` argument, which allows one to override a column
  type for a given table, if the default type is not appropriate.

- Support for databases with non UTF-8 encodings. Use the `encoding`
  parameter to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
  to specify the database encoding.

- Support for the SQL Connection Pane in the RStudio IDE.

- Unknown fields no longer throw a warning, instead they signal a custom
  condition, which can be caught if desired with

  withCallingHandlers(expr, odbc_unknown_field_type = function(e) {…} )

- Conversion to and from timezones is handled by the
  [cctz](https://github.com/google/cctz) library. If the database is in
  a non-UTC timezone it can be specified with the `timezone` parameter
  to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- Time objects are converted to and from `hms` objects.

- 64 bit integers are converted to and from `bit64` objects.

- Support table creation for Impala and Hive Databases
  ([\#38](https://github.com/r-dbi/odbc/issues/38),
  [@edgararuiz](https://github.com/edgararuiz)).

## odbc 1.0.1

CRAN release: 2017-02-07

- Fixes for the CRAN build machines
  - Do not force c++14 on windows
  - Turn off database tests on CRAN, as I think they will be difficult
    to debug even if databases are supported.
- Added a `NEWS.md` file to track changes to the package.

## odbc 1.0.0

CRAN release: 2017-02-05

- Initial odbc release
