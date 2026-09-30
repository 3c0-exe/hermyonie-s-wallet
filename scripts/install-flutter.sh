#!/usr/bin/env bash
set -euo pipefail
FLUTTER_VERSION=3.47.5
if [ ! -x .flutter-sdk/bin/flutter ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git .flutter-sdk
fi
.flutter-sdk/bin/flutter config --no-analytics
.flutter-sdk/bin/flutter pub get
