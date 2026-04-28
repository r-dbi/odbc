## Current state

odbc is stable, though there are still corner cases where it could have issues with certain database backends. Mostly around text encodings, datetime and logical formats.

## Known outstanding issues

The "Developing odbc" vignette at `vignette("develop")` contains instructions on running the tests locally, which is important to make the feedback loop shorter.

The hardest part of maintaining odbc is often an issue only occurs with a specific database, and setting up the environment for that database usually takes a non-trivial amount of time.

## Vendored cctz

The vendored copy in `src/cctz` was last updated against `google/cctz`
commit `00fc77b843504f231f89c13eff86327c444094e8`.

Relative to that upstream commit, the odbc package intentionally keeps the
following deltas for R package inclusion:

- Upstream `.github/` is omitted from the vendored copy.
- Upstream `testdata/` is omitted from the vendored copy.
- `src/cctz/Makefile` is patched so recursive builds from `src/Makevars` keep
  the cctz include path and PIC flags required for R shared-library builds.
- `src/cctz/Makefile` adds `time_zone_name_win.o` on Windows because upstream
  now ships `src/time_zone_name_win.cc`, and omitting it breaks Windows
  linking.
- `src/cctz/Makefile` add `-DNDEBUG` to `CPPFLAGS`.
- `src/cctz/src/time_zone_fixed.cc` keeps odbc-specific fixed-offset zone names
  based on `Etc/GMT` rather than upstream `Fixed/UTC`, matching odbc timestamp
  offset behavior.
- `src/cctz/src/time_zone_fixed.cc` also retains local formatting behavior for
  fixed offsets, including compact hour formatting, omission of zero
  minute/second components, and a runtime error in place of the upstream
  assert.
- `src/cctz/src/time_zone_format.cc` keeps historical odbc compatibility
  patches for Windows/MinGW-era behavior: forcing `HAS_STRPTIME`, disabling the
  `tm_year` saturation branch for large positive values, and bypassing the
  `strptime()` call in `ParseTM()`.

When updating cctz again, compare the vendored tree against upstream and carry
these deltas forward only if they are still required by odbc.

## Future directions

- Convert from using Rcpp to using cpp11.
  This is not urgent, but basically all other r-lib/tidyverse packages have been converted.

- Look into updating the version of nanodbc to a newer version.
  This is complicated by the fact that nanodbc now requires C++14, so it can't really be a drop in unless we want to bump up odbc to require C++14.
  Alternatively look into the recent nanodbc comments and port them to the current version of odbc.
  We did this for other use cases.
