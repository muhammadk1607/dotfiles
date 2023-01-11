#!/usr/bin/env bash

# Usage `list_from_file "path/to/file.txt"`
list_from_file() {
  local packages=''
  while IFS= read -r line; do
    packages+=" $line"
  done <"$1"
  echo "$packages"
}
