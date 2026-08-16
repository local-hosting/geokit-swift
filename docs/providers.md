# Map provider alignment

See also [`geokit/docs/providers.md`](../geokit/docs/providers.md) (canonical cross-platform overview).

## Platform matrix

| Concern | TypeScript (`geokit`) | Swift (`GeoKitContract`) |
|---------|----------------------|---------------------------|
| Static provider id | `maptiler` \| `mapbox` | `mapbox` \| `apple` |
| Registry | `configureUIProviders` | `GeoKitMapProviderRegistry.configure(provider:mapbox:apple:)` |
| Env | `GEOKIT_MAP_PROVIDER`, `MAP_PROVIDER` | Same + `Info.plist` |
| Mapbox runtime | `mapbox-provider.ts` | `GeoKitUIMapbox/` |
| Apple runtime | — | `GeoKitUI/Providers/Apple/` |

Globe CDN (JWT, cell layers, DMA shapes) is **not** in either package — use `@local-hosting/globe-static`.

## Provider switching

```swift
import GeoKitContract

// Global default (before map content mounts)
GeoKitMapProviderRegistry.configure(provider: .apple, apple: .init(mapStyle: .standard))

// Per-map override
MapContentRequest(
    id: "card-1",
    phase: .live,
    isExpanded: true,
    mapProviderId: .mapbox
)
```

Env / Info.plist: `GEOKIT_MAP_PROVIDER=apple` or `mapbox` (aliases: `mapkit`, `apple-maps`).

Registration: `GeoKitRegister.activate()` wires both `GeoKitMapboxBootstrap` and `GeoKitAppleProviderRegistration`.

---

## Swift parity checklist — Mapbox vs Apple

Legend: **✅** both providers · **🟡** partial / different behavior · **❌** not supported · **➖** N/A on Swift

Scope: **Places / card map shell** (`GeoKitMapContent`, lifecycle, pins). Not the full web `gk-*` component library.

### Map shell (contract lifecycle)

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| Placeholder phase | ✅ | ✅ | `MapContentPhase` |
| Snapshot phase | ✅ | ✅ | Provider-specific capture |
| Live phase | ✅ | ✅ | `GeoKitMapboxMapContent` / `GeoKitMapKitMapContent` |
| Provider registry + per-map id | ✅ | ✅ | `MapProviderId` |
| Env / Info.plist default | ✅ | ✅ | Default **mapbox** |
| Bootstrap | ✅ | ➖ | Mapbox: token + SDK init; Apple: no token step |
| `GeoKitMapBootstrap.prepare()` | ✅ | ✅ | Dispatches to registered provider |

### Card map UX

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| Pins + selection | ✅ | ✅ | `MapPin` |
| User location puck | ✅ | ✅ | `showUserPuck` |
| Camera frame resolver | ✅ | ✅ | Shared `MapCameraFrameResolver` |
| Expand / collapse transitions | ✅ | ✅ | Frozen snapshot underlay |
| Touch shield during interaction | ✅ | ✅ | |
| Zoom level reporting | ✅ | ✅ | |
| Programmatic zoom +/- chrome | ✅ | 🟡 | Mapbox surface has explicit +/- enablement |
| iOS live map | ✅ | ✅ | `#if os(iOS)` |
| macOS live map | ❌ | ❌ | Package lists macOS; map UI is iOS-gated today |

### Styling

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| Custom style URI | ✅ | ❌ | `mapStyleURI` on request — Mapbox only |
| Built-in map styles | ✅ | ✅ | Mapbox Studio URI vs `AppleMapsProviderConfig.MapStyle` (`standard`, `imagery`, `hybrid`) |
| Transit / POI label tuning | ✅ | ➖ | `GeoKitMapboxStyleImportConfigurator` |

### Snapshots

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| Card peek snapshot capture | ✅ | ✅ | `GeoKitSnapshotCaptureRegistry` |
| Pin compositing on snapshot | ✅ | ✅ | `GeoKitSnapshotPinDraw` |
| Defer capture while live GL mounted | ✅ | ➖ | `MapSnapshotCaptureGate` — Mapbox only |
| Live-map safe window | ✅ | ➖ | `GeoKitMapboxLiveMapRegistry` |

### Map overlays (web geokit equivalents)

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| `gk-layer` / choropleth | ❌ | ❌ | Web only |
| `gk-isochrone` on map | ❌ | ❌ | Web only; core math in `GeoKitCore` |
| `gk-h3` viewport layer | ❌ | ❌ | Web only; H3 utils in `GeoKitCore` |
| Route progress `line-gradient` | ❌ | ❌ | Web: `buildRouteProgressGradient`; not wired in Swift UI yet |
| Custom GeoJSON layers | 🟡 | ❌ | Mapbox could add layers; not in card shell API |

### Utilities (provider-agnostic — `GeoKitCore`)

| Feature | Mapbox | Apple | Notes |
|---------|--------|-------|-------|
| `Interpolation.alongPath` | ✅ | ✅ | Same module |
| `Bearing.randomPointInCircle` | ✅ | ✅ | |
| `GeoKitColor` / `Easing` | ✅ | ✅ | |
| `GeoKitRouteProgressGradient` | ✅ | ✅ | Expression builder; map wiring TBD |
| `GeoKitMapViewportSettledCoordinator` | ✅ | ✅ | Generic coordinator |
| `GeoKitMapboxViewportSettled.observe` | ✅ | ➖ | Mapbox Maps SDK only |

---

## Known Swift gaps (track here)

- [ ] macOS map surface (today iOS-only despite `Package.swift` platforms)
- [ ] Wire `GeoKitRouteProgressGradient` into a Mapbox line layer for commute/route UIs
- [ ] Document when hosts should prefer Apple (no token, native UX) vs Mapbox (Studio styles)
- [ ] Parity test matrix: same `MapContentRequest` on both providers (snapshot bytes / camera frame)
- [ ] Apple: optional elevation / realistic style when MapKit adds stable APIs

---

## Map cards — external live host (Places + GeoKitTestApp)

Live map content mounts **inside** the active card slot (stack center or expanded overlay). Expand/collapse animates the card chrome; the map is clipped to that slot.

### Host wiring

1. `GeoKitCenterCardMediaStore.syncCollectionMedia` — focused static snapshot, then `liveCardID`.
2. `GeoKitMapContentWithLifecycle` — resolves phase from `MapStagePolicy` + `MapLifecycleState`.
3. Register providers via `GeoKitRegister.activate()` before first map mount.
