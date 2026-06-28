#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -scheme GeoKitTestApp -project GeoKitTestApp/GeoKitTestApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
