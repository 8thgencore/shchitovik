#!/bin/bash
# Pure Dart packages (engine/*) run with `dart test`, Flutter packages with `flutter test`.
# Every package is tested from its own directory: native assets (sqlite3 build hooks) are
# only built for the package under test.
set -e
cd "$(dirname "$0")/.."
source scripts/_env.bash
root="$(pwd)"
mkdir -p reports

workspace_packages | while read -r dir; do
  [ -d "$dir/test" ] || continue
  printf "\nTesting %s\n" "$dir"
  name="$(echo "$dir" | tr '/' '_')"
  if grep -qE '^\s+sdk: flutter' "$dir/pubspec.yaml"; then
    (cd "$dir" && $FLUTTER test --no-pub --coverage --file-reporter "json:$root/reports/$name.json")
  else
    (cd "$dir" && $DART test --reporter expanded --file-reporter "json:$root/reports/$name.json")
  fi
done
