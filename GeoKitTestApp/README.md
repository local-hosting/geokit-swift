# GeoKitTestApp

Standalone iOS demo for GeoKit map surfaces, static/dynamic pins, snapshots, provider switching, and expand/collapse.

## Run in Xcode

Open `GeoKitTestApp.xcodeproj` and run the **GeoKitTestApp** scheme on an iOS simulator.

## Run from CLI

```bash
cd GeoKitTestApp
xcodebuild -resolvePackageDependencies -project GeoKitTestApp.xcodeproj -scheme GeoKitTestApp
xcodebuild -project GeoKitTestApp.xcodeproj -scheme GeoKitTestApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -disableAutomaticPackageResolution build
```

Mapbox token: `GeoKitTestApp/Info.plist` (`MBXAccessToken`).

## UI tests

```bash
./scripts/run-ui-tests.sh              # all UI tests (card switch + regression)
./scripts/run-ui-tests.sh smoke        # launch only
./scripts/run-ui-tests.sh switch       # card switch regression (5 tests)
./scripts/run-ui-tests.sh regression   # provider, expand/collapse, flash, multi-pin (4 tests)
```

## Map capture regression (unit + Static API smoke)

From the geokit-swift package root:

```bash
./scripts/test-map-capture.sh
```

## Map provider picker

Use the **Mapbox / Apple** segmented control (top-right) to switch map providers at runtime without rebuilding.

## Demo features

- Six pinned cities with hoisted map card (New York, Louisville, Chicago, Austin, Seattle, Miami)
- NYC ships a second pin (Brooklyn Bridge) for multi-pin selection regression
- Static snapshot and live map markers via GeoKit lifecycle
- Card paging at the bottom
- Tap card to expand/collapse full-screen map
- UITest mode (`-UITestMode`) exposes city and pin selectors for automation
