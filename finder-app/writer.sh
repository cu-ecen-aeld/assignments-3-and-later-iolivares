#!/bin/bash

if [ -z "$1" ]; then
  echo  "Error: missing argument: write file path"
  exit 1
fi
writefile="$1"

if [ -z "$2" ]; then
  echo "Error: missing argument: content string"
  exit 1
fi
writestr="$2"

dir=$(dirname "$writefile")
if ! mkdir -p "$dir"; then
  echo "Error: could not create directory $dir"
  exit 1
fi

if ! echo "$writestr" > "$writefile"; then
  echo "Error: could not write to file $writefile"
  exit 1
fi
