#!/bin/bash
 
BIN_PATH=/usr/local/bin

if [ $(ls $BIN_PATH | grep -c xchelper) -gt 0 ]; then
  rm $BIN_PATH/xchelper
fi

echo "Thanks for trying out xchelper. It's been uninstalled."