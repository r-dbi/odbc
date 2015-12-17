#!/bin/bash

usage()
{
    (
        echo "usage: ${0##*/}"
        echo "Release new stable version of nanodbc."
    ) >&2
    exit 1
}

if echo "$*" | egrep -q -- "--help|-h"; then
    usage
fi

pushd "$(git rev-parse --show-toplevel)" >/dev/null
source scripts/shell_control

if [[ -n "$(git status -s)" ]]; then
    abort "changes exist in workspace, please commit or stash them first."
fi

ask "Make version $(cat VERSION) the new STABLE release?"
if [[ "$REPLY" == "y" ]]; then
    set -e
    run "git push -f origin master:release"
fi
