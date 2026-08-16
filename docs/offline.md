> TypeScript entry: [`geokit/docs/offline.md`](../geokit/docs/offline.md)

# Offline maps (Swift)

Contract types live in **`GeoKitContract`** (`MapOffline.swift`, `MapOfflinePolicy.swift`).

## Swift-only notes

- **`MapCameraStore`** already persists camera per `mapId` (`UserDefaults`).
- **`GeoKitMapProviderSnapshotCache`** is in-memory today; Tier B adds disk persistence for snapshot fallback.
- **`GeoKitMapboxOfflineRegionStore`** (`GeoKitUIMapbox`) — Mapbox `TileStore` offline regions keyed by `mapId`.
- **MapKit** reports best-effort coverage only (`MapOfflinePlatform.nativeMapKit`).

## Tier D context load hook

- Set `offlineContext` on `MapContentRequest` (or `GeoKitMapContentWithLifecycle`)
- Default Mapbox handler registers in `GeoKitMapboxBootstrap`
- Override: `GeoKitRuntime.prefetchOfflineRegionOnContextLoad`

## Tests

`Tests/GeoKitContractTests/MapOfflinePolicyTests.swift`
