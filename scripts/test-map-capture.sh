#!/usr/bin/env bash
# GeoKit map capture regression — static API smoke + snapshot content policy.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "[test-map-capture] snapshot content policy (unit)"
./scripts/test-ios.sh --target GeoKitUITests --filter GeoKitMapSnapshotContentPolicyTests
echo "[test-map-capture] Mapbox Static Images API smoke"
./scripts/test-ios.sh --target GeoKitUIMapboxTests --filter GeoKitStaticSnapshotIntegrationTests
