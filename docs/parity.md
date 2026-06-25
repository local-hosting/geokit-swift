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

## Tier 2 — map UI lifecycle

| Node | Swift |
|------|-------|
| `ensureMapReady` / bootstrap phases | `GeoKitMapBootstrap.prepareMapbox()` |
| placeholder / snapshot / live | `MapContentPhase`, `MapContentPhaseResolver`, `GeoKitMapContentWithLifecycle` |
| `MapStagePolicyResolver` | `MapStagePolicyResolver` (GeoKitContract) |
| `whenStyleReady`, `delayForWebGLRelease` | `GeoKitMapLifecycle.waitForStyleReady`, `.delayForWebGLRelease` |
| `STUCK_PLACEHOLDER_MS`, WebGL budget | `GeoKitMapLifecycleConstants` |

## Tier 3 — Node-only (out of scope)

CDN choropleth, MCP map tools, provider registry, full Turf suite (area-heavy polygon ops use simplified Swift repair).

## Known differences

- `getCenter` on Node uses Turf for feature collections; Swift uses axis-aligned bbox center.
- `fitViewport(mapSize:)` is Swift-only size-aware zoom.
- Node bearing/geohash helpers are curried; Swift uses named parameters.
- GeoJSON repair omits Turf-backed sliver/area filters; ring close + dedupe parity is covered.
