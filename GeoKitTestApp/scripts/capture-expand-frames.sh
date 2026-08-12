#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/GeoKitTestApp.xcodeproj"
SCHEME="GeoKitTestApp"
BUNDLE_ID="ca.corio.geokit-test"
SIM_ID="${SIMULATOR_ID:-0F4AABDD-22FE-4EAE-9242-50E7329712C4}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/GeoKitTestApp-build}"
FRAME_COUNT="${FRAME_COUNT:-24}"
FRAME_INTERVAL="${FRAME_INTERVAL:-0.5}"
PRE_CAPTURE_WAIT="${PRE_CAPTURE_WAIT:-3.0}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$ROOT/.captures/expand-frames-$STAMP"
mkdir -p "$OUT_DIR"
echo "Building GeoKitTestApp..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$SIM_ID" -derivedDataPath "$DERIVED" build >/dev/null
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GeoKitTestApp.app"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
echo "Launching capture mode..."
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID" -CaptureExpandFrames >/dev/null
echo "Waiting ${PRE_CAPTURE_WAIT}s..."
sleep "$PRE_CAPTURE_WAIT"
MANIFEST="$OUT_DIR/manifest.txt"
{
  echo "capture=expand-frames"
  echo "simulator=$SIM_ID"
  echo "frame_count=$FRAME_COUNT"
  echo "frame_interval_s=$FRAME_INTERVAL"
  echo "animation_speed=0.1"
  echo "---"
} >"$MANIFEST"
for ((i = 1; i <= FRAME_COUNT; i++)); do
  frame="$(printf '%s/frame-%03d.png' "$OUT_DIR" "$i")"
  xcrun simctl io "$SIM_ID" screenshot "$frame"
  echo "frame-$i $(date +%H:%M:%S) $(basename "$frame")" >>"$MANIFEST"
  printf 'Captured %03d/%03d\r' "$i" "$FRAME_COUNT"
  sleep "$FRAME_INTERVAL"
done
echo ""
echo "Done. Frames: $OUT_DIR"
echo "open \"$OUT_DIR\""
