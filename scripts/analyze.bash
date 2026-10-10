#!/bin/bash
set -e
cd "$(dirname "$0")/.."
source scripts/_env.bash

$FLUTTER analyze . --no-pub
