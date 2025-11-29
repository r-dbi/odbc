# NA

## Current state

odbc is stable, though there are still corner cases where it could have
issues with certain database backends. Mostly around text encodings,
datetime and logical formats.

## Known outstanding issues

The “Developing odbc” vignette at
[`vignette("develop")`](https://odbc.r-dbi.org/dev/articles/develop.md)
contains instructions on running the tests locally, which is important
to make the feedback loop shorter.

The hardest part of maintaining odbc is often an issue only occurs with
a specific database, and setting up the environment for that database
usually takes a non-trivial amount of time.

## Future directions

- Convert from using Rcpp to using cpp11. This is not urgent, but
  basically all other r-lib/tidyverse packages have been converted.

- Look into updating the version of nanodbc to a newer version. This is
  complicated by the fact that nanodbc now requires C++14, so it can’t
  really be a drop in unless we want to bump up odbc to require C++14.
  Alternatively look into the recent nanodbc comments and port them to
  the current version of odbc. We did this for other use cases.
