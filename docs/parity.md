> **Canonical parity doc:** [`geokit/docs/parity.md`](../geokit/docs/parity.md) — module map, fixture CI, **API cheat sheet** (Tier 1 / 1.5 / Turf rules).

# Swift GeoKit parity (Swift-only notes)

Provider checklist: [`providers.md`](providers.md).

## Fixture CI

From Twinfile repo root:

```bash
bash geokit/src/core/scripts/verify-parity.sh
```

Or from `geokit/`: `yarn verify:parity`. Export / drift-check details: [geokit `parity.md` — Fixture contract](../geokit/docs/parity.md#fixture-contract).

## Tier 2 — offline policy fixtures

`offline` in `parity-fixtures.json` locks zoom clamp, tile count, coverage thresholds, and the oversized-prefetch error. `GeoKitCoreTests` checks `MapOfflinePolicyResolver` against those numbers. Lifecycle timing stays a conceptual mirror.

## Tier 2 — map UI lifecycle

| Node (`@local-hosting/geokit/ui`, contract) | Swift |
|------|-------|
| `ensureMapReady` / bootstrap phases | `GeoKitMapBootstrap.prepareMapbox()` |
| placeholder / snapshot / live | `MapContentPhase`, `MapContentPhaseResolver`, `GeoKitMapContentWithLifecycle` |
| `MapStagePolicyResolver` | `MapStagePolicyResolver` (GeoKitContract) |
| `whenStyleReady`, `delayForWebGLRelease` | `GeoKitMapLifecycle.waitForStyleReady`, `.delayForWebGLRelease` |
| `STUCK_PLACEHOLDER_MS`, WebGL budget | `GeoKitMapLifecycleConstants` |

## Swift-specific behavior

- **`fitViewport(mapSize:)`** — size-aware zoom on `BoundsCalculator` (no Node equivalent).
- **`Buffer.bufferLine` / `bufferPolygon`** — throw `BufferError.unsupportedGeometry` (use Node `@local-hosting/geokit/core/turf` or point buffers only).
- **Point buffer rings** — Turf Swift circle (`vertices + 1`); Node `bufferPoint` is turf-free spherical (fixture tolerances cover drift).
- **GeoJSON repair** — ring close + dedupe parity; no Turf sliver/area filters from Node.
- **API shape** — named Swift static methods vs curried TypeScript helpers.

## Map provider switching

| Node | Swift |
|------|-------|
| `MapStaticProviderId` (`maptiler` \| `mapbox`) | `MapProviderId` (`mapbox` \| `apple`) |
| `configure({ maptiler, mapbox })` | `GeoKitMapProviderRegistry.configure(provider:mapbox:apple:)` |
| `GEOKIT_MAP_PROVIDER` / `MAP_PROVIDER` env | Same keys + `Info.plist` `GEOKIT_MAP_PROVIDER` |
| `provider="mapbox"` on map element | `MapContentRequest.mapProviderId` per map |

MapKit: `GeoKitMapKitMapContent`; Mapbox: `GeoKitMapboxMapContent`. Default **mapbox** on iOS (incl. CarPlay) and visionOS; **apple** on tvOS (no Mapbox SDK).

## Platform support (live maps)

Full matrix: [`platforms.md`](platforms.md).

| Platform | MapKit | Mapbox |
|----------|--------|--------|
| iOS / iPad / CarPlay / Catalyst | Yes | Yes |
| visionOS | Yes | Yes (Mapbox Maps SDK ≥ 11.2) |
| tvOS | Yes (default) | No — coerced to MapKit |

## Daylight parity helpers (v5)

- `Interpolation.alongPath` ↔ `interpolateAlongPath`
- `Bearing.randomPointInCircle` / `randomPointInCircleKm` ↔ `randomPointInCircle`
- `GeoKitColor`, `GeoKitPaletteCycler` ↔ geokit color utils
- `Easing.easeInOutCubic` ↔ `easeInOutCubic`
- `GeoKitRouteProgressGradient` ↔ `buildRouteProgressGradient`
- `GeoKitMapViewportSettledCoordinator` / `GeoKitMapboxViewportSettled` ↔ `onMapViewportSettled`

Offline: [`offline.md`](offline.md) · [geokit `offline.md`](../geokit/docs/offline.md).
