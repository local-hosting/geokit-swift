# GeoKitTestApp

Standalone iOS demo for GeoKit map surface, snapshots, and stack expand/collapse.

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

## Map provider picker

Use the **Mapbox / Apple** segmented control (top-right) to switch map providers at runtime without rebuilding.
