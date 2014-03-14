#!/bin/bash

set -e

if ! TAG=`git describe --exact-match 2>/dev/null`; then
  echo "This commit not a tag so not creating a release"
  exit 0
fi

echo "Creating GitHub release for $TAG"

[ -e .travis/GITHUBTOKEN ] && . .travis/GITHUBTOKEN

if [[ -z "$GITHUBTOKEN" ]]; then
  echo "Error: GITHUBTOKEN not set"
  exit 1
fi

