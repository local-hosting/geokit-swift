# GeoKit (Swift)

Swift counterpart to [`@corio-platforms/geokit`](https://github.com/corio-platforms/geokit) — geo math in **GeoKitCore**, map UI in **GeoKitUI**, runtime contract in **GeoKitContract**, dynamic registration in **GeoKit**.

## Targets

| Target | Role | Node equivalent |
|--------|------|-----------------|
| **GeoKitCore** | Bounds, distance, bearing, coordinates, H3 — no Mapbox | `@geokit` root / `utils/*` |
| **GeoKitContract** | `GeoKitRuntime`, `MapContentRequest` — linked by host before dlopen | app wiring + `types/` |
| **GeoKitUI** | SwiftUI map surface, markers, snapshots, theme | `@geokit/ui` |
| **GeoKit** | `dlopen` entry + `GeoKitRegister` | side-effect registration |
| **GeoKitTestApp** | Standalone iOS demo (`GeoKitTestApp/GeoKitTestApp.xcodeproj`) | geokit Vite demo |

## Source layout

Mirrors Node geokit folder domains:

```text
Sources/
  GeoKitCore/
    Constants/
    Types/
    Utils/{bounds,bearing,coordinates,distance,h3}/
  GeoKitContract/
    Runtime/
    Types/
  GeoKitUI/
    Bootstrap/
    Policy/
    Components/{Map,Point,Callout}/
    Utils/
  GeoKit/
    Register/
Tests/
  GeoKitCoreTests/
    Utils/{bounds,bearing,coordinates,distance,h3}/
    Fixtures/
```

## Phase 1 (current)

- GeoKitCore geo calculators with shared JSON fixtures vs Node geokit
- GeoKitContract lazy-load registration surface
- GeoKitUI map content (placeholder, snapshot, live Mapbox)
- GeoKit dynamic framework registers UI via `GeoKitRegister`

## Usage

```swift
import GeoKitCore

let center = BoundsCalculator.centerAndZoom(from: [-74.006, 40.7128, -73.9855, 40.758])
let meters = Distance.haversineMeters(
    from: LatLon(latitude: 40.7128, longitude: -74.006),
    to: LatLon(latitude: 34.0522, longitude: -118.2437)
)
let cell = try H3.coordinatesToCell(LatLon(latitude: 40.7128, longitude: -74.006), resolution: 9)
```

Host apps link **GeoKitContract** only; `dlopen` GeoKit.framework after the map host paints, then call `GeoKitRegister.registerMapContent()`.

Apps that link map UI directly (no `dlopen`) can depend on **GeoKitUI** + **GeoKitContract**.

## Development

```bash
swift build
swift test
```

## Parity fixtures

`Tests/GeoKitCoreTests/Fixtures/parity-fixtures.json` is the cross-platform contract. Regenerate from Node with:

```bash
yarn --cwd ../geokit export:parity-fixtures
```

## Related

- Node geokit: `../geokit` (corio monorepo nested repo)
- Plan: Swift GeoKit package migration phases (Places stack-first shell → map content → offline)
