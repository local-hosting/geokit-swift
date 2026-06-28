#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build --target GeoKitCoreTests
swift build --target GeoKitContractTests
swift test --skip-build --filter GeoKitCoreTests
swift test --skip-build --filter GeoKitContractTests
