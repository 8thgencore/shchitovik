#!/bin/bash
cd "$(dirname "$0")/.."
source scripts/_env.bash

workspace_packages | while read -r dir; do
  (cd "$dir" && $FLUTTER clean >/dev/null 2>&1 || rm -rf .dart_tool build)
done
