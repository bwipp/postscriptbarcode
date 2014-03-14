#!/bin/bash

set -e

if ! TAG=`git describe --exact-match 2>/dev/null`; then
  echo "Not tag so not creating a release"
  exit 0
fi

echo "Creating GitHub release for $TAG"

if [[ -z "$GITHUBTOKEN" ]]; then
  echo "Error: GITHUBTOKEN not set in environment"
  exit 1
fi

