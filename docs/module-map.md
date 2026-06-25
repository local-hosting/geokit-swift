# GeoKit Swift module map

Folder layout mirrors Node `@corio-platforms/geokit` domains.

| Node export | Swift target | Swift path | Parity tier |
|-------------|--------------|------------|-------------|
| `@geokit` / `utils/bounds` | GeoKitCore | `Utils/bounds/` | 1 |
| `@geokit/bearing` | GeoKitCore | `Utils/bearing/` | 1 |
| `@geokit/coordinates` | GeoKitCore | `Utils/coordinates/` | 1 |
| `@geokit/distance` | GeoKitCore | `Utils/distance/` | 1 |
| `@geokit/h3` | GeoKitCore | `Utils/h3/` | 1 |
| `src/types` (geo) | GeoKitCore | `Types/` | 1 |
| `src/constants` | GeoKitCore | `Constants/` | 1 |
| host map request types | GeoKitContract | `Types/` | 2 |
| runtime registration | GeoKitContract | `Runtime/` | 2 |
| `@geokit/ui` | GeoKitUI | `Components/`, `Utils/`, `Bootstrap/` | 2 |
| card stack stage policy | GeoKitUI | `Policy/` | 2 (Swift-only) |
| `dlopen` registration | GeoKit | `Register/` | 2 |

See [`parity.md`](parity.md) for API-level fixture coverage.
