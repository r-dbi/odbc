#!/usr/bin/env bash

shopt -s extglob

clang_format_3_9=$(command -v clang-format-3.9)
if [ ! -z "$clang_format_3_9" ]; then
  clang_format=$clang_format_3_9
else
  clang_format=$(command -v clang-format)
fi
if [ -z "$clang_format" ]; then
  echo "Could not find recent version of clang-format"
  exit 1
fi
"$clang_format" -i src/!(RcppExports).@(c|h|cpp) && git diff-files -U --exit-code
