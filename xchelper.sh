#!/bin/bash

VERSION=0.0.1
ACTIONS=(install run test xcodeproj-schemes swiftlint pod-lib-lint pod-trunk-deploy)

usage() {
  cat <<EOF
Usage: A tool for iOS developers to automate tedious tasks like install, run, test.

SYNOPSIS:
xchelper [action ...] [-w] [Build workspace path option]
  
Actions:
  install
      Install project dependencies
  run
      Install project dependencies, and open workspace.
  test
      Test a scheme from the build root (SYMROOT).  This requires specifying a scheme and optionally a destination.
  xcodeproj-schemes
      To list all available schemes for the project in your current directory.
  pod-lib-lint
      Validates a Pod.
  pod-trunk-deploy
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

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function sh() {
  printf "${GREEN}$ $@${NC}\n"
  $@
}

function logger_cmd() {
  printf "${GREEN}$@${NC}\n"
}

function warning() {
  printf "${YELLOW}warning: $@${NC}\n"
}

function info() {
  echo "info: $@"
}

function setup_xcodeproj() {
  XCODE_DERIVED_DATA_PATH=$PWD/build
  get_xcode_destination
  get_xcodeproj_workspace
}

function install_project_dependencies() {
  get_gemfile_directory
  if [ $XCODE_GEMFILE_DIRECTORY ]; then
    sh bundle install --verbose
    sh bundle exec rake
    return
  fi

  get_podfile_directory
  sh pod install --project-directory=${XCODE_PROFILE_DIRECTORY} --verbose
}

function get_xcode_destination() {
  if [ -z $XCODE_DESTINATION ]; then
    local device_name=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}'`
    XCODE_DESTINATION="platform=iOS Simulator,name=$device_name"
  fi
}

function get_xcodeproj_workspace() {
  if [ -z $XCODE_WORKSPACE ]; then
    workspaces=($(find $PWD/ -name "*.xcworkspace" | awk '{print length($0), $0}' | sort -n | awk '{print $2}'))
    XCODE_WORKSPACE=${workspaces[0]}
  fi
}

function get_xcodeproj_schemes() {
  if [ -z $XCODE_SCHEMES ]; then
    XCODE_SCHEMES=($(echo `xcodebuild -workspace $XCODE_WORKSPACE -list -json` | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['workspace']['schemes']"))
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
  info "get xcodeproj xctest schemes ..."
  get_xcodeproj_schemes
  for scheme in ${XCODE_SCHEMES[@]}; do
    local test_host_list=( $(echo `xcodebuild -workspace $XCODE_WORKSPACE -scheme $scheme -showBuildSettings -json` | ruby -e "require 'json'; puts JSON.parse(STDIN.gets).map { |value| value['buildSettings']['TEST_HOST'] }.reject { |value| value.to_s.empty? }") )
    if [ ${#test_host_list[@]} -gt 0 ]; then
      if [ -z $XCODE_XCTEST_SCHEMES ]; then
        XCODE_XCTEST_SCHEMES=()
        XCODE_XCTEST_SCHEMES[${#XCODE_XCTEST_SCHEMES[@]}]=$scheme
      fi
    fi
  done
}

function get_gemfile_directory() {
  gemfile_paths=($(find $PWD/ -name Gemfile | awk '{print length($0), $0}' | sort -n | awk '{print $2}'))
  # 默认使用查到到的第一个 Gemfile
  if [ ${#gemfile_paths[@]} -gt 0 ]; then
    gemfile_path=${gemfile_paths[0]}
    XCODE_GEMFILE_DIRECTORY=$(dirname ${gemfile_path})
  fi
}

function get_podfile_directory() {
  podfile_paths=($(find $PWD/ -name Podfile))
  # 默认使用查到到的第一个 Podfile
  podfile_path=${podfile_paths[0]}
  XCODE_PROFILE_DIRECTORY=$(dirname ${podfile_path})
}

function build_for_testing() {
  get_xcodeproj_xctest_schemes

  if [ ${#XCODE_XCTEST_SCHEMES[@]} -eq 0 ]; then
    warning "No such xctest scheme, skipping ..."
    exit 0
  fi

  for scheme in ${XCODE_XCTEST_SCHEMES[@]}; do
    sh set -ox pipefail && xcodebuild build-for-testing -workspace $XCODE_WORKSPACE -scheme $scheme -destination "$XCODE_DESTINATION" -derivedDataPath 'build/' | xcpretty
  done
}

function test_without_building() {
  local xctestrun_files=( $(find $XCODE_DERIVED_DATA_PATH -name *.xctestrun) )
  if [ ${#xctestrun_files[@]} -eq 0 ]; then
    warning "No such xctest run file, skipping ..."
    exit 0
  fi

  # 默认使用第一个 xctest run file
  local xctestrun_file=${xctestrun_files[0]}
  sh set -ox pipefail && xcodebuild test-without-building -xctestrun $xctestrun_file -destination "$XCODE_DESTINATION" | xcpretty
}

######################
## Actions

function install() {
  install_project_dependencies
}

function run() {
  install_project_dependencies
  sh open $XCODE_WORKSPACE
}

function test() {
  build_for_testing
  test_without_building
}

function xcodeproj-schemes() {
  get_xcodeproj_schemes

  echo ${XCODE_SCHEMES[@]}
}

function swiftlint() {
  if which swiftlint >/dev/null; then
    if [ -e .swiftlint.yml ]; then
      sh command swiftlint lint --strict
    else
      warning "No such file or directory: '.swiftlint.yml', skipping ..."
    fi
  else 
    warning "SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
}

function pod-lib-lint() {
  if [ -e *.podspec ]; then
    sh pod lib lint --allow-warnings --verbose
  else
    warning "No such file or directory: '*.podspec', skipping ..."
  fi
}

function pod-trunk-deploy() {
  sh pod trunk push *.podspec --allow-warnings --verbose
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

function main() {
  setup_xcodeproj

  echo "------------------------"
  logger_cmd "Action: ${ACTION} ..."
  echo "------------------------"
  ${ACTION}
}

main