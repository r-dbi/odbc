#!/bin/bash -ue

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

abort()
{
    echo $'\e[1;31merror:' "$1" $'\e[0m' >&2
    exit 1
}

if [[ -n "$(git status -s)" ]]; then
    abort "changes exist in workspace, please commit or stash them first."
fi

pushd "$(git rev-parse --show-toplevel)" >/dev/null

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
echo "$version" > VERSION
git add VERSION
set -x
git commit -m "Preparing $version release."
