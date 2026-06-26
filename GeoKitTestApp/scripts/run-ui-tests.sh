#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/GeoKitTestApp.xcodeproj"
SCHEME="GeoKitTestApp"
DESTINATION="${GEOKIT_UI_TEST_DESTINATION:-platform=iOS Simulator,id=0F4AABDD-22FE-4EAE-9242-50E7329712C4}"
TARGET="GeoKitTestAppUITests/GeoKitDemoCardSwitchUITests"

case "${1:-all}" in
  smoke)   TEST="$TARGET/testAppLaunchesAndShowsRoot" ;;
  launch)  TEST="$TARGET/testLaunchFrontCardClearsLoadingSpinner" ;;
  switch)  TEST="$TARGET/testSwitchToLouisvilleClearsLoadingSpinner" ;;
  all)     TEST="$TARGET" ;;
  *)
    echo "usage: $0 [smoke|launch|switch|all]" >&2
    exit 1
    ;;
esac

cd "$ROOT"

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -parallel-testing-enabled NO
  -maximum-concurrent-test-simulator-destinations 1
)

if [[ "${GEOKIT_UI_TEST_REBUILD:-0}" == "1" ]]; then
  echo "== build-for-testing =="
  xcodebuild build-for-testing "${XCODEBUILD_ARGS[@]}"
fi

echo "== test-without-building: $TEST =="
xcodebuild test-without-building "${XCODEBUILD_ARGS[@]}" -only-testing:"$TEST"
