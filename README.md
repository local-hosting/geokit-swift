# GeoKit (Swift)

Swift counterpart to [`@corio-platforms/geokit`](https://github.com/corio-platforms/geokit) — geo math in **GeoKitCore**, map content in **GeoKit** (dynamic framework), runtime contract in **GeoKitContract**.

## Targets

| Target | Role | Node equivalent |
|--------|------|-----------------|
| **GeoKitCore** | Bounds, distance, bearing, coordinates, H3 — no Mapbox | `@geokit` root |
| **GeoKitContract** | `GeoKitRuntime`, `MapContentRequest` — linked by host before dlopen | app wiring |
| **GeoKit** | Map surface, markers, snapshots, offline (Phase 3+) | `@geokit/ui` |
| **GeoKitTestApp** | Standalone demo app (Phase 2+) | geokit Vite demo |

## Phase 1 (current)

- GeoKitCore geo calculators with shared JSON fixtures vs Node geokit
- GeoKitContract lazy-load registration surface
- GeoKit dynamic framework stub (`GeoKitRegister` placeholder content)

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

Host apps link **GeoKitContract** only; `dlopen` GeoKit.framework after the card stack paints, then call `GeoKitRegister.registerMapContent()`.

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
