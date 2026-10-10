#!/bin/bash
# Usage: codegen.bash build|watch
set -e
cd "$(dirname "$0")/.."
source scripts/_env.bash
mode="${1:-build}"

workspace_packages | while read -r dir; do
  if grep -q build_runner "$dir/pubspec.yaml"; then
    printf "\nGenerating files for %s\n" "$dir"
    (cd "$dir" && $DART run build_runner "$mode" -d)
  fi
done
