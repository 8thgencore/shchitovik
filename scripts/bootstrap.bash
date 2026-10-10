#!/bin/bash
set -e
cd "$(dirname "$0")/.."
source scripts/_env.bash

$FLUTTER pub get
engine_packages | while read -r dir; do
  (cd "$dir" && $DART pub get)
done
bash scripts/codegen.bash build
