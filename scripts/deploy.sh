#!/bin/bash

#
# 1. Bump the version in https://github.com/BlueIntent/xchelper/blob/main/xchelper.sh#L5; commit changes; push changes to GitHub.
# 2. Bump the git tag and push tag; https://github.com/BlueIntent/xchelper/tags create release.
# 3. Make a new release on homebrew.

VERSION=$(sh $PWD/xchelper.sh --version | awk -F ' ' {'print $3'})
echo "current version ${VERSION} \n"

if [ -z $1 ]; then
  cat <<EOF
ERROR: should put a version number.
eg: sh scripts/deploy.sh 1.0.0"
EOF
  exit 1
fi

echo "brew test ..."
brew test xchelper --verbose

DEPLOY_VERSION=$1
echo "deploy version: $DEPLOY_VERSION ..."

if [ $(git tag | grep -c $DEPLOY_VERSION) -gt 0 ]; then
  echo "ERROR: tag '$DEPLOY_VERSION' already exists"
  exit 1
fi
git tag $DEPLOY_VERSION
git push --tags --verbose
echo "create a release from https://github.com/BlueIntent/xchelper/tags."
echo "make a new release on homebrew."