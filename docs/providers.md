# Map provider alignment

See also [`geokit/docs/providers.md`](../geokit/docs/providers.md).

| Concern | TypeScript (`@geokit`) | Swift (`GeoKitContract`) |
|---------|------------------------|---------------------------|
| Static provider id | `MapStaticProviderId`: `maptiler` \| `mapbox` | `MapProviderId`: `mapbox` \| `apple` |
| Registry | `src/api/registry` | `GeoKitMapProviderRegistry` |
| Env | `GEOKIT_MAP_PROVIDER`, `MAP_PROVIDER` | Same + `Info.plist` |
| Mapbox runtime | `src/ui/providers/mapbox-provider.ts` | `GeoKitUIMapbox` |
| Apple runtime | — | `GeoKitUI/Providers/Apple` |

Globe CDN (JWT, cell layers, DMA shapes) is **not** in either package — use `@doppler-group/globe-static`.
