#!/bin/bash
# Pass --check to fail on unformatted files (CI).
set -e
cd "$(dirname "$0")/.."
source scripts/_env.bash

args=()
[ "$1" == "--check" ] && args+=(--set-exit-if-changed --output=none)

files=$(workspace_packages | while read -r dir; do
  for d in lib test bin; do
    if [ -d "$dir/$d" ]; then
      find "$dir/$d" -name '*.dart' ! -name '*.*.dart' -not -path '*/generated/*'
    fi
  done
done)

if [ -n "$files" ]; then
  $DART format "${args[@]}" $files
fi
