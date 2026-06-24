# Node vs Swift GeoKit parity

## Tier 1 — shared fixtures (v1)

| Module | Node export | Swift API | Fixture |
|--------|-----------|-----------|---------|
| Bounds | `calculateCenterAndZoom`, `calculateZoomFromBounds` | `BoundsCalculator.centerAndZoom`, `.zoom` | `bounds.*` |
| Distance | `haversineMeters` | `Distance.haversineMeters` | `distance.*` |
| Bearing | `bearing` | `Bearing.initial` | `bearing.*` |
| Coordinates | `isValidCoordinate` | `Coordinates.isValid` | `validation.*` |
| H3 | `coordinatesToH3` (h3-js) | `H3.coordinatesToCell` (SwiftyH3) | `h3.nycRes9` |

**Epsilon:** lat/lon ±0.0001 where centers are compared; distance ranges use Node test bands; H3 cell ids must match exactly (same h3 reference implementation family).

## Tier 2 — behavioral (planned)

- Map surface lifecycle, snapshot ↔ live handoff
- Card stack stage policy (`MapStagePolicyResolver`)
- Offline tile regions (Swift-only today)

## Tier 3 — Node-only (out of scope v1)

CDN choropleth, MCP map tools, provider registry, full turf suite.

## Known differences

- `getCenter` on Node uses Turf for feature collections; Swift v1 uses axis-aligned bbox center (matches Node for rectangular bounds).
- `fitViewport(mapSize:)` is Swift-only size-aware zoom; Node step-table zoom is ported verbatim in `BoundsCalculator.zoom`.
