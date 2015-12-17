#!/bin/bash

usage()
{
    (
        echo "usage: ${0##*/} [major|minor|patch]"
        echo "Publish new version of nanodbc."
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

version=$(cat VERSION)
major="$(echo "$version" | cut -d. -f1)"
minor="$(echo "$version" | cut -d. -f2)"
patch="$(echo "$version" | cut -d. -f3)"

if [[ "$1" == "major" ]]; then
    major="$(( major + 1 ))"
    minor="0"
    patch="0"
elif [[ "$1" == "minor" ]]; then
    minor="$(( minor + 1 ))"
    patch="0"
elif [[ "$1" == "patch" ]]; then
    patch="$(( patch + 1 ))"
else
    usage
fi

version="$major.$minor.$patch"
tag="v$version"
show "Publishing nanodbc version: $version"
set -ue
run "echo '$version' > VERSION"
run "git add VERSION"
run "git commit -m 'Preparing $version release.'"
run "git tag -f '$tag'"
run "git push -f origin '$tag'"
run "git push -f origin master:latest"
