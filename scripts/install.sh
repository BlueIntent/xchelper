#!/bin/bash

upstream_github_url="https://github.com/BlueIntent/xchelper"

PWD_DIR=$PWD
OUTPUT_DIR=$(mktemp -d -t xchelper-release)
echo $OUTPUT_DIR
git clone $upstream_github_url $OUTPUT_DIR
cd $OUTPUT_DIR && make install && cd $PWD_DIR
sudo rsync -r $OUTPUT_DIR/build/package/* /usr/local/bin
rm -rf $OUTPUT_DIR
echo "Successfully installed"
xchelper --version
