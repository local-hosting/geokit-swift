# GeoKit Swift module map

**TypeScript ↔ Swift imports and API names:** see the cheat sheet in [geokit `parity.md`](../geokit/docs/parity.md#api-cheat-sheet-cross-platform).

Quick path reference (Swift target → `Sources/`):

| Swift target | Folder |
|--------------|--------|
| GeoKitCore | `GeoKitCore/Utils/{bounds,bearing,coordinates,distance,geohash,geojson,h3,turf,…}/`, `Types/`, `Constants/` |
| GeoKitContract | `GeoKitContract/{Types,Lifecycle,Policy,Runtime,Providers}/` |
| GeoKitUI | `GeoKitUI/{Components,Bootstrap,Utils,Policy,Stores}/` |
| GeoKitUIMapbox | `GeoKitUIMapbox/` |
| GeoKit | `GeoKit/Register/` |

Fixture tiers and epsilons: [geokit `parity.md` — Tiers](../geokit/docs/parity.md#tiers). Swift-only notes: [`parity.md`](parity.md).
