#!/bin/bash

set -e

TAG=$1  # Debug override of tag

GITUSER=terryburton
GITREPO=postscriptbarcode
RELEASEFILES=build/release/*

if [[ -z "$TAG" ]]; then
  if ! TAG=`git describe --exact-match 2>/dev/null`; then
    echo "This commit not a tag so not creating a release"
    exit 0
  fi
fi

echo "Creating GitHub release for $TAG"

[ -e .travis/GITHUBTOKEN ] && . .travis/GITHUBTOKEN

if [[ -z "$GITHUBTOKEN" ]]; then
  echo "Error: GITHUBTOKEN not set"
  exit 1
fi

if [[ -z "$RELEASEFILES" ]]; then
  echo "Error: No release files"
  exit 1
fi

echo -n "Create draft release... "
JSON=$(cat <<EOF
{
  "tag_name": "$TAG",
  "target_commitish": "master",
  "name": "$TAG: New release",
  "draft": true,
  "prerelease": false
}
EOF
)
RESULT=`curl -s -w "\n%{http_code}\n" -H "Authorization: token $GITHUBTOKEN" --data "$JSON" "https://api.github.com/repos/$GITUSER/$GITREPO/releases"`
if [ "`echo "$RESULT" | tail -1`" != "201" ]; then
  echo FAILED
  echo "$RESULT" 
  exit 1
fi 
ID=`echo "$RESULT" | sed -ne 's/^  "id": \(.*\),$/\1/p'`
if [[ -z "$ID" ]]; then
  echo FAILED
  echo "$RESULT" 
  exit 1
fi
echo DONE

for FILE in $RELEASEFILES; do
  FILE=`basename $FILE`
  echo -n "Uploading $FILE... "
  UPLOAD_URL="https://uploads.github.com/repos/$GITUSER/$GITREPO/releases/$ID/assets?name=$FILE"
  RESULT=`curl -s -w "\n%{http_code}\n" \
       -H "Authorization: token $GITHUBTOKEN" \
       -H "Accept: application/vnd.github.manifold-preview" \
       -H "Content-Type: application/zip" \
       --data-binary "@$FILE" \
       "$UPLOAD_URL"`
  if [ "`echo "$RESULT" | tail -1`" != "201" ]; then
    echo FAILED
    echo "$RESULT" 
    exit 1
  fi
  echo DONE
done 

echo -n "Publishing release... "
JSON=$(cat <<EOF
{
  "draft": false
}
EOF
)
RESULT=`curl -s -w "\n%{http_code}\n" --request PATCH -H "Authorization: token $GITHUBTOKEN" --data "$JSON" "https://api.github.com/repos/$GITUSER/$GITREPO/releases/$ID"`
if [ "`echo "$RESULT" | tail -1`" = "200" ]; then
  echo DONE
else
  echo FAILED
  echo "$RESULT" 
  exit 1
fi 
