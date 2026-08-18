# GeoKit Swift module map

| Node export | Swift target | Swift path | Parity tier |
|-------------|--------------|------------|-------------|
| `@geokit/core` | GeoKitCore | `Utils/` (barrel) | 1 |
| `@geokit` / `utils/bounds` | GeoKitCore | `Utils/bounds/` | 1 |
| `@geokit/bearing` | GeoKitCore | `Utils/bearing/` | 1 |
| `@geokit/coordinates` | GeoKitCore | `Utils/coordinates/` | 1 |
| `@geokit/distance` | GeoKitCore | `Utils/distance/` | 1 |
| `@geokit/h3` | GeoKitCore | `Utils/h3/` | 1 |
| `@geokit/geohash` | GeoKitCore | `Utils/geohash/` | 1 |
| `@geokit/geojson` | GeoKitCore | `Utils/geojson/`, `Types/GeoJSONTypes.swift` | 1 |
| `src/types` (geo) | GeoKitCore | `Types/` | 1 |
| `src/constants` | GeoKitCore | `Constants/` | 1 |
| host map request types | GeoKitContract | `Types/` | 2 |
| map lifecycle / stage policy | GeoKitContract | `Lifecycle/`, `Policy/` | 2 |
| runtime registration | GeoKitContract | `Runtime/` | 2 |
| `@geokit/ui` map lifecycle | GeoKitUI | `Utils/GeoKitMapLifecycle.swift`, `Components/Map/` | 2 |
| `@geokit/ui` | GeoKitUI | `Components/`, `Utils/`, `Bootstrap/` | 2 |
| `dlopen` registration | GeoKit | `Register/` | 2 |

| `@geokit/turf` | GeoKitCore | `Utils/turf/` + siblings | 1.5 |
| `@geokit/contract` | GeoKitContract | `Lifecycle/`, `Providers/` | 2 |


See [`parity.md`](parity.md) for API-level fixture coverage.
