#!/bin/bash -ue

usage()
{
    (
        echo "usage: ${0##*/}"
        echo "Release new version of nanodbc."
    ) >&2
    exit 1
}

if echo "$*" | egrep -q -- "--help|-h"; then
    usage
fi

abort()
{
    echo $'\e[1;31merror:' "$1" $'\e[0m' >&2
    exit 1
}

if [[ -n "$(git status -s)" ]]; then
    abort "changes exist in workspace, please commit or stash them first."
fi

pushd "$(git rev-parse --show-toplevel)" >/dev/null

set -x
git push -f origin master:release
