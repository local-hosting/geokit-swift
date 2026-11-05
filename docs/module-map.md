# GeoKit Swift module map

| Node export | Swift target | Swift path | Parity tier |
|-------------|--------------|------------|-------------|
| `@twinfile/geokit/core` | GeoKitCore | `Utils/` (barrel) | 1 |
| `@twinfile/geokit/core/geokit/core/bounds` | GeoKitCore | `Utils/geokit/core/bounds/` | 1 |
| `@twinfile/geokit/core/geokit/core/bearing` | GeoKitCore | `Utils/geokit/core/bearing/` | 1 |
| `@twinfile/geokit/core/geokit/core/coordinates` | GeoKitCore | `Utils/geokit/core/coordinates/` | 1 |
| `@twinfile/geokit/core/geokit/core/distance` | GeoKitCore | `Utils/geokit/core/distance/` | 1 |
| `@twinfile/geokit/h3` | GeoKitCore | `Utils/geokit/h3/` | 1 |
| `@twinfile/geokit/core/geokit/core/geohash` | GeoKitCore | `Utils/geokit/core/geohash/` | 1 |
| `@twinfile/geokit/core/geokit/core/geojson` | GeoKitCore | `Utils/geokit/core/geojson/`, `Types/GeoJSONTypes.swift` | 1 |
| `src/types` (geo) | GeoKitCore | `Types/` | 1 |
| `src/constants` | GeoKitCore | `Constants/` | 1 |
| host map request types | GeoKitContract | `Types/` | 2 |
| map lifecycle / stage policy | GeoKitContract | `Lifecycle/`, `Policy/` | 2 |
| runtime registration | GeoKitContract | `Runtime/` | 2 |
| `@twinfile/geokit/ui` map lifecycle | GeoKitUI | `Utils/GeoKitMapLifecycle.swift`, `Components/Map/` | 2 |
| `@twinfile/geokit/ui` | GeoKitUI | `Components/`, `Utils/`, `Bootstrap/` | 2 |
| `dlopen` registration | GeoKit | `Register/` | 2 |
| `@twinfile/geokit/core/geokit/core/turf` | GeoKitCore | `Utils/geokit/core/turf/` + siblings | 1.5 |
| `@twinfile/geokit/core/geokit/core/contract` | GeoKitContract | `Lifecycle/`, `Providers/` | 2 |

See [`parity.md`](parity.md) for API-level fixture coverage.
