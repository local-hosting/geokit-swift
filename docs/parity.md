# Node vs Swift GeoKit parity

## Tier 1 — shared fixtures (v3)

| Module | Node export | Swift API | Fixture |
|--------|-----------|-----------|---------|
| Bounds | `getBounds`, `getCenter`, `calculateCenterAndZoom`, `calculateZoomFromBounds` | `BoundsCalculator.fromCoordinates`, `.center`, `.centerAndZoom`, `.zoom` | `bounds.*` |
| Distance | `haversineMeters`, `withinDistance` | `Distance.haversineMeters`, `.withinDistance` | `distance.*` |
| Bearing | `bearing`, `finalBearing`, `midpoint`, `destinationMeters` | `Bearing.initial`, `.final`, `.midpoint`, `.destinationMeters` | `bearing.*` |
| Coordinates | `isValidCoordinate`, `toLatLon` / `toLonLat`, array helpers | `Coordinates.isValid`, `.toLatLon`, `.toLonLat`, `.toLatLonArray`, `.toLonLatArray` | `validation.*` |
| H3 | `coordinatesToH3`, `h3ToParent`, `h3ToChildren`, `h3Neighbors`, `h3AreNeighbors`, `h3EdgeLength`, `h3CellArea` | `H3.coordinatesToCell`, `.parent`, `.children`, `.neighbors`, `.areNeighbors`, `.edgeLength`, `.cellArea` | `h3.*` |
| Geohash | `encodeGeohash`, `decodeGeohash`, `geohashBounds`, `geohashNeighbors`, `validateGeohash` | `Geohash.encode`, `.decode`, `.bounds`, `.neighbors`, `.isValid` | `geohash.*` |
| GeoJSON | `getCoordinates`, `getFeatureId`, `validateGeoJSON`, `repairGeometry` | `GeoJSONHelpers`, `GeoJSONValidation`, `GeoJSONRepair` | `geojson.*` |

**Epsilon:** lat/lon ±0.0001 where centers are compared; distance ranges use Node test bands; H3 cell ids must match exactly; geohash strings must match exactly.

## Tier 1.5 — Turf-backed geometry (v4)

Swift GeoKitCore depends on [turf-swift](https://github.com/mapbox/turf-swift) for measurement and containment. Fixtures live under `turf.*` in `parity-fixtures.json` (version 4).

| Module | Node export | Swift API | Turf primitive |
|--------|-----------|-----------|----------------|
| Containment | `isPointInPolygon`, `boundsContains`, `boundsIntersects` | `Containment.*` | `Polygon.contains`, `BoundingBox.contains` |
| Centroid | `polygonCentroid`, `pointsCentroid` | `Centroid.*` | `Polygon.centroid` |
| Area | `polygonArea`, `boundsArea` | `Area.*` | `Polygon.area` |
| Length | `lineLengthMeters`, `perimeterMeters` | `Length.*` | `LineString.distance` |
| Buffer | `bufferPoint` | `Buffer.bufferPoint` | `Polygon(center:radius:vertices:)` (turf-circle) |
| Conversions | `toDMS`, `fromDMS`, `coordinatesToDMS` | `Conversions.*` | pure math |
| Bounds geo | `bboxToPolygon`, `getBounds(geometry)` | `BoundsGeo.*` | `BoundingBox`, bbox polygon |
| Coordinates | `detectAndConvertCoordinateFormat`, `extractCoordinates` | `CoordinateExtraction.*` | format heuristics |

**Epsilon:** area/length tolerances are looser than Tier 1 because turf-swift and Turf.js differ slightly on geodesic math. Point buffer ring count uses Turf Swift circle semantics (`steps + 1` vertices).

**Not in Turf Swift:** `bufferLine` / `bufferPolygon` throw `BufferError.unsupportedGeometry` (no turf-buffer port).

## Tier 2 — map UI lifecycle

| Node | Swift |
|------|-------|
| `ensureMapReady` / bootstrap phases | `GeoKitMapBootstrap.prepareMapbox()` |
| placeholder / snapshot / live | `MapContentPhase`, `MapContentPhaseResolver`, `GeoKitMapContentWithLifecycle` |
| `MapStagePolicyResolver` | `MapStagePolicyResolver` (GeoKitContract) |
| `whenStyleReady`, `delayForWebGLRelease` | `GeoKitMapLifecycle.waitForStyleReady`, `.delayForWebGLRelease` |
| `STUCK_PLACEHOLDER_MS`, WebGL budget | `GeoKitMapLifecycleConstants` |

## Tier 3 — Node-only (out of scope)

CDN choropleth, MCP map tools, provider registry (Mapbox + Apple Maps), full Turf suite (union/difference/simplify/clustering).

## Known differences

- `getCenter` on Node uses Turf for feature collections; Swift uses axis-aligned bbox center.
- `fitViewport(mapSize:)` is Swift-only size-aware zoom.
- Node bearing/geohash helpers are curried; Swift uses named parameters.
- GeoJSON repair omits Turf-backed sliver/area filters; ring close + dedupe parity is covered.
- Point buffers use Turf Swift circle (`vertices + 1` ring); Node `@turf/buffer` on points produces a denser ring.
- Line/polygon buffers require Node geokit until turf-swift adds turf-buffer.

## Map provider switching (Swift)

| Node | Swift |
|------|-------|
| `MapStaticProviderId` (`maptiler` \| `mapbox`) | `MapProviderId` (`mapbox` \| `apple`) |
| `configure({ maptiler, mapbox })` | `GeoKitMapProviderRegistry.configure(provider:mapbox:apple:)` |
| `GEOKIT_MAP_PROVIDER` / `MAP_PROVIDER` env | Same keys + `Info.plist` `GEOKIT_MAP_PROVIDER` |
| `provider="mapbox"` on map element | `MapContentRequest.mapProviderId` per map |

Apple Maps uses MapKit (`GeoKitMapKitMapContent`); Mapbox uses MapboxMaps (`GeoKitMapboxMapContent`). Default remains **mapbox** for backward compatibility.
