#!/bin/bash

ACTIONS=(run start test xcodeproj_schemes pod_lint pod_deploy)
XCODE_DESTINATION="platform=iOS Simulator,OS=14.5,name=iPhone 8"
VERSION=0.0.1

usage() {
  cat <<EOF
Usage: A tool for iOS developers to automate tedious tasks like run, test.

SYNOPSIS:
xchelper [action ...] [-w] [Build workspace path option]
  
Actions:
  run
      Build an Xcode project.
  start
      Build an Xcode project, and open workspace.
  test
      Test a scheme from the build root (SYMROOT).  This requires specifying a scheme and optionally a destination.
  xcodeproj_schemes
      To list all available schemes for the project in your current directory.
  pod_lint
      Validates a Pod.
  pod_deploy
      Publish a podspec.

Parameters:
   --workspace | -w
      Build the workspace name.xcworkspace.
   --destination | -d
      Use the destination device described by destinationspecifier.  Defaults to a destination that is compatible with the
           selected scheme.  See the Destinations section below for more details.
   --scheme | -s
      Build the scheme specified by schemename.

Options:
   --help | -h
      Print complete usage.
   --version | -v
      Print version info.

LICENSE MIT
Copyright (c) 2021 qiuzhifei <qiuzhifei521@gmail.com>. All rights reserved.
EOF
  exit 0
}

version() {
  echo "xchelper version ${VERSION}"
  exit 0
}

function setup_xcodeproj() {
  get_xcodeproj_workspace
}

function get_xcodeproj_workspace() {
  if [ -z $XCODE_WORKSPACE ]; then
    workspaces=($(find ./ -name "*.xcworkspace"))
    XCODE_WORKSPACE=${workspaces[0]}
  fi
}

function get_xcodeproj_schemes() {
  if [ -z $XCODE_SCHEMES ]; then
    XCODE_SCHEMES=($(xcodebuild -workspace */*.xcworkspace -list 2>/dev/null | sed '1,/Schemes:/d' | grep -v CordovaLib | sed -e 's/^[ \t]*//'))
  fi
}

function get_xcodeproj_scheme() {
  get_xcodeproj_schemes
  if [ -z $XCODE_SCHEME ]; then
    # pod repo, scheme 是第二个
    XCODE_SCHEME=${XCODE_SCHEMES[0]}
  fi
}

function get_xcodeproj_xctest_schemes() {
  get_xcodeproj_schemes
  for scheme in ${XCODE_SCHEMES[@]}; do
    local xctest_count=$(xcodebuild -workspace */*.xcworkspace -scheme $scheme -showBuildSettings | grep WRAPPER_EXTENSION | grep -c xctest)
    if [ $xctest_count -gt 0 ]; then
      if [ -z $XCODE_XCTEST_SCHEMES ]; then
        XCODE_XCTEST_SCHEMES=()
        XCODE_XCTEST_SCHEMES[${#XCODE_XCTEST_SCHEMES[@]}]=$scheme
      fi
    fi
  done
}

function get_gemfile_directory() {
  gemfile_paths=($(find ./ -name Gemfile | awk '{print length($0), $0}' | sort -n | awk '{print $2}'))
  # 默认使用查到到的第一个 Gemfile
  if [ ${#gemfile_paths[@]} -gt 0 ]; then
    gemfile_path=${gemfile_paths[0]}
    XCODE_GEMFILE_DIRECTORY=$(dirname ${gemfile_path})
  fi
}

function get_podfile_directory() {
  podfile_paths=($(find ./ -name Podfile))
  # 默认使用查到到的第一个 Podfile
  podfile_path=${podfile_paths[0]}
  XCODE_PROFILE_DIRECTORY=$(dirname ${podfile_path})
}

######################
## Actions

function run() {
  get_gemfile_directory
  if [ $XCODE_GEMFILE_DIRECTORY ]; then
    bundle install --verbose
    bundle exec rake
    return
  fi

  get_podfile_directory
  pod install --project-directory=${XCODE_PROFILE_DIRECTORY} --verbose
}

function start() {
  run
  open $XCODE_WORKSPACE
}

function test() {
  get_xcodeproj_xctest_schemes

  for scheme in ${XCODE_XCTEST_SCHEMES[@]}; do
    set -o pipefail | xcodebuild -workspace $XCODE_WORKSPACE -scheme $scheme -destination "$XCODE_DESTINATION" build test | xcpretty
  done
}

function xcodeproj_schemes() {
  get_xcodeproj_schemes

  echo ${XCODE_SCHEMES[@]}
}

function pod_lint() {
  pod lib lint --allow-warnings --verbose
}

function pod_deploy() {
  pod trunk push *.podspec --allow-warnings --verbose
}

######################

while [ $# != 0 ]; do
  case $1 in
  --workspace | -w)
    XCODE_WORKSPACE=$2
    shift 2
    ;;
  --destination | -d)
    XCODE_DESTINATION=$2
    shift 2
    ;;
  --scheme | -s)
    XCODE_SCHEME=$2
    shift 2
    ;;
  --help | -h)
    usage
    shift
    ;;
  --version | -v)
    version
    shift
    ;;
  *)
    if [ -z $ACTION ]; then
      if [[ "${ACTIONS[@]}" =~ $1 ]]; then
        ACTION=$1
      fi
    fi
    shift
    ;;
  esac
done

######################

if [ -z $ACTION ]; then
  usage
  exit 1
fi

setup_xcodeproj
${ACTION}
