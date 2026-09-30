#!/usr/bin/env bash
set -euo pipefail
.flutter-sdk/bin/flutter build web --release --base-href / --pwa-strategy=none
