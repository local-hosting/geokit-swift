# GeoKit (Swift)

Swift counterpart to [`@twinfile/geokit`](https:/github.com/twinfile/geokit) — geo math in **GeoKitCore**, map UI in **GeoKitUI**, runtime contract in **GeoKitContract**, dynamic registration in **GeoKit**.

## Targets

| Target | Role | Node equivalent |
|--------|------|-----------------|
| **GeoKitCore** | Bounds, distance, bearing, coordinates, H3 — no Mapbox | `@twinfile/geokit/core`, `@twinfile/geokit/h3` |
| **GeoKitContract** | `GeoKitRuntime`, `MapContentRequest` — linked by host before dlopen | app wiring + `types/` |
| **GeoKitUIMapbox** | Mapbox provider, snapshots, live surface | optional Mapbox dep |
| **GeoKitUI** | SwiftUI map surface, markers, snapshots, theme | `@twinfile/geokit/ui` |
| **GeoKit** | `dlopen` entry + `GeoKitRegister` | side-effect registration |
| **GeoKitTestApp** | Standalone iOS demo (`GeoKitTestApp/GeoKitTestApp.xcodeproj`) | geokit Vite demo |

## Source layout

Mirrors Node geokit folder domains:

```text
Sources/
  GeoKitCore/
    Constants/
    Types/
    Utils/{bounds,bearing,coordinates,distance,h3,geohash,geojson}/
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
    Utils/{bounds,bearing,coordinates,distance,h3,geohash,geojson}/
    Fixtures/
```

## Phase 2 (current)

- GeoKitCore geohash + GeoJSON validation/repair
- GeoKitContract map lifecycle phase resolver
- GeoKitUI `GeoKitMapContentWithLifecycle` for placeholder / snapshot / live

## Phase 1

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
let mid = Bearing.midpoint(
    from: LatLon(latitude: 40.7128, longitude: -74.006),
    to: LatLon(latitude: 34.0522, longitude: -118.2437)
)
let cell = try H3.coordinatesToCell(LatLon(latitude: 40.7128, longitude: -74.006), resolution: 9)
let parent = try H3.parent(of: cell, resolution: 8)
```

Host apps link **GeoKitContract** only; `dlopen` GeoKit.framework after the map host paints, then call `GeoKitRegister.registerMapContent()`.

Apps that link map UI directly (no `dlopen`) can depend on **GeoKitUI** + **GeoKitContract**.

## H3

H3 indexing uses the [`SwiftyH3`](https:/github.com/pawelmajcher/SwiftyH3) package (wraps Uber's H3 C library). `GeoKitCore`'s `H3` enum is a thin adapter over it. Bump the version range in `Package.swift` when updating.

## Development

```bash
swift build
swift test --filter GeoKitCoreTests
swift test --filter GeoKitContractTests
./scripts/test-ui.sh
```

## Parity fixtures

`Tests/GeoKitCoreTests/Fixtures/parity-fixtures.json` is the cross-platform contract. Regenerate from Node with:

```bash
yarn --cwd ../geokit/src/geokit/core verify:parity   # or export:parity-fixtures only
```

## Related

- Node geokit: [`../geokit`](../geokit) (sibling in the Twinfile workspace)
- Plan: Swift GeoKit package migration phases (Places stack-first shell → map content → offline)

## Map provider switching

Mirrors `@twinfile/geokit/ui` provider selection:

```swift
import GeoKitContract

/ Global default (before registerMapContent)
GeoKitMapProviderRegistry.configure(provider: .apple, apple: .init(mapStyle: .standard))

/ Per-map override
MapContentRequest(
    id: "card-1",
    phase: .live,
    isExpanded: true,
    mapProviderId: .mapbox
)
```

Environment / Info.plist: `GEOKIT_MAP_PROVIDER=apple` or `mapbox` (aliases: `mapkit`, `apple-maps`).

## Map cards — external live host (Places + GeoKitTestApp)

Live map content mounts **inside** the active card slot (stack center or expanded overlay). Expand/collapse animates the card chrome; the map is clipped to that slot — no external host or frame preference bridge.

### Host wiring

1. ``GeoKitCenterCardMediaStore.syncCollectionMedia`` — focused static snapshot, then ``liveCardID``.
2. Card content: ``GeoKitMapCardSlot`` with ``MapCardMediaPresentationContext`` (static peek for fan/back; live only on top slot).
3. Expanded overlay uses the same slot via ``CardExpanded`` — live stays in the overlay tree for the collapse spring.

### Boot sequence

```text
layout size → silent static capture → liveCardID → live tiles paint (no center static overlay when live-first)
```

Back cards are **static snapshots only** — never live. Only the top stack card (or its expanded overlay) mounts live GPU data via ``liveCardID``. Use ``MapMediaSurfaceLayout.mapContentSize`` with your footer inset for capture/live alignment.

GeoKitTestApp is the reference implementation for Places.

