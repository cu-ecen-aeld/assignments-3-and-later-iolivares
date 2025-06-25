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
mkdir -p "$dir"

echo "$writestr" > "$writefile"
