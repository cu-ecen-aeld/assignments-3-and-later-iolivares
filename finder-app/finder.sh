#!/bin/bash

if [ -z "$1" ]; then
  echo  "Error: missing argument: search directory path"
  exit 1
fi
filesdir="$1"

if [ ! -d "$filesdir" ]; then
  echo "Error: specified search directory does not exist"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: missing argument: search string"
  exit 1
fi
searchstr="$2"

files=$(find "$filesdir" -type f)

all_matches=0
for file in $files; do
  file_matches=$(grep -c "$searchstr" "$file")
  all_matches=$((all_matches + file_matches))
done

num_files=$(echo "$files" | wc -l)

echo "The number of files are ${num_files} and the number of matching lines are ${all_matches}"
