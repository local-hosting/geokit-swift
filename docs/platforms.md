# GeoKit map platforms

UIKit-based targets supported by **GeoKitUI** (MapKit) and **GeoKitUIMapbox** (Mapbox Maps SDK v11.25+).

## Live map matrix

| Platform | Apple MapKit (`.apple`) | Mapbox (`.mapbox`) | Default when unset |
|----------|-------------------------|--------------------|--------------------|
| iOS / iPadOS / **CarPlay** | Yes | Yes | `.mapbox` |
| Mac Catalyst | Yes (iOS slice) | Yes (iOS slice) | `.mapbox` |
| visionOS | Yes | Yes (native SDK since Mapbox 11.2) | `.mapbox` |
| tvOS | Yes | No (Mapbox SDK has no tvOS product) | `.apple` |

Configure explicitly with `GeoKitMapProviderRegistry.configure(provider:)` or `GEOKIT_MAP_PROVIDER` / `MAP_PROVIDER` (`mapbox`, `apple`, `mapkit`).

On **tvOS**, a configured `.mapbox` provider is coerced to `.apple` at runtime.

## CarPlay

**CarPlay is the iOS binary slice** — no separate GeoKit target or `#if` gate. Any host with a CarPlay navigation entitlement that already links GeoKit on iPhone gets the same MapKit and Mapbox backends in the CarPlay scene (`CPWindow` / `CPTemplateApplicationScene`).

- **MapKit** — native CarPlay map templates (`CPMapTemplate`) and MapKit views in the CarPlay window.
- **Mapbox** — Mapbox Maps SDK for iOS (same product GeoKit links); render into the CarPlay-connected `CPWindow`. Mapbox Navigation SDK adds higher-level CarPlay UI (`CarPlayManager`); GeoKit uses **Maps** only, so CarPlay map chrome is host-owned.

Requires Apple's CarPlay navigation entitlement and scene delegate wiring in the app — GeoKit does not register CarPlay scenes.

## Registration

`GeoKitRegister.registerMapContent()`:

- **iOS, visionOS, tvOS** — registers `GeoKitMapContent` and activates MapKit (`GeoKitUIRegistration`).
- **iOS, visionOS** — also activates Mapbox (`GeoKitUIMapboxRegistration`). Includes CarPlay (iOS).
- Other platforms — no live map registration (host must not depend on maps there).

## H3 (GeoKitCore)

Uber H3 (`Ch3.xcframework` (SPM target `GeoKitCh3`)) links on **iOS and macOS** only. On tvOS and visionOS, `H3` APIs throw `H3Error.unavailableOnPlatform`.

## References

- [Mapbox — Work with visionOS](https:/docs.mapbox.com/ios/maps/guides/work-with-visionos/)
- [Mapbox Navigation — CarPlay](https:/docs.mapbox.com/ios/navigation/guides/system-integration/carplay/) (Navigation SDK; Maps SDK uses same iOS slice)
- Provider switching: `docs/parity.md` § Map provider switching
