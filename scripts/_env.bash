#!/bin/bash
# Resolves the Flutter/Dart binaries: FVM-pinned SDK if present, otherwise PATH.
if command -v fvm >/dev/null 2>&1 && [ -f "$(git rev-parse --show-toplevel)/.fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
else
  FLUTTER="flutter"
  DART="dart"
fi

# All packages (dirs with pubspec.yaml), excluding the root and tool output.
workspace_packages() {
  find app common engine -name pubspec.yaml \
    -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/ephemeral/*' \
    -exec dirname {} \; | sort
}

# Standalone pure Dart packages, resolved outside the Flutter workspace.
engine_packages() {
  find engine -mindepth 2 -maxdepth 2 -name pubspec.yaml -exec dirname {} \; | sort
}
