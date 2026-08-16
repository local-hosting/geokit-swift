#!/usr/bin/env bash
# GeoKitUIMapbox is iOS-only. Use xcodebuild on the iOS Simulator — not bare `swift test` on macOS.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${TEST_IOS_DEST:-platform=iOS Simulator,name=iPhone 17 Pro}"
SCHEME="${TEST_IOS_SCHEME:-GeoKit-Package}"
TARGET="GeoKitUIMapboxTests"
FILTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --filter) FILTER="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
ARGS=(test -scheme "$SCHEME" -destination "$DEST")
if [[ -n "$FILTER" ]]; then
  ARGS+=(-only-testing:"${TARGET}/${FILTER}")
fi
cd "$ROOT"
xcodebuild "${ARGS[@]}"
