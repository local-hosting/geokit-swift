#if os(iOS) || os(visionOS)

import CoreLocation
import Foundation
import GeoKitContract
import MapboxMaps
import Turf

public enum GeoKitMapboxOfflineRegionError: Error, Equatable, Sendable {
    case invalidLoadOptions
    case invalidStyleURI(String)
}

/// Mapbox `TileStore` offline region downloads keyed by `mapId`.
@MainActor
public final class GeoKitMapboxOfflineRegionStore {
    public static let shared = GeoKitMapboxOfflineRegionStore()

    private let tileStore: TileStore
    private let offlineManager: OfflineManager
    private var activeDownloads: [String: Cancelable] = [:]
    private var progressByMapId: [String: MapOfflineCoverage] = [:]
    private let progressDefaults: UserDefaults
    private let progressKeyPrefix = "geokit.mapbox.offline.progress."

    public init(
        tileStore: TileStore = .default,
        progressDefaults: UserDefaults = .standard
    ) {
        self.tileStore = tileStore
        self.offlineManager = OfflineManager()
        self.progressDefaults = progressDefaults
    }

    @discardableResult
    public func prefetch(
        request: MapOfflinePrefetchRequest,
        styleURI: StyleURI,
        policy: MapOfflinePolicy = .cacheFirst,
        progress: ((MapOfflineCoverage) -> Void)? = nil,
        completion: @escaping (Result<MapOfflineCoverage, Error>) -> Void
    ) -> Cancelable? {
        let normalized: MapOfflinePrefetchRequest
        do {
            normalized = try MapOfflinePolicyResolver.validate(request: request, platform: .nativeMapbox)
        } catch {
            completion(.failure(error))
            return nil
        }

        cancelPrefetch(mapId: normalized.mapId)

        guard let loadOptions = Self.makeLoadOptions(request: normalized, styleURI: styleURI, offlineManager: offlineManager)
        else {
            completion(.failure(GeoKitMapboxOfflineRegionError.invalidLoadOptions))
            return nil
        }

        let required = MapOfflinePolicyResolver.estimateTileCount(
            bounds: normalized.bounds,
            zoomRange: normalized.zoomRange
        )

        let cancelable = tileStore.loadTileRegion(forId: normalized.mapId, loadOptions: loadOptions) { [weak self] tileProgress in
            guard let self else { return }
            let coverage = MapOfflinePolicyResolver.coverage(
                tilesCached: Int(tileProgress.completedResourceCount),
                tilesRequired: max(Int(tileProgress.requiredResourceCount), required),
                policy: policy
            )
            self.progressByMapId[normalized.mapId] = coverage
            self.persistProgress(coverage, mapId: normalized.mapId)
            progress?(coverage)
        } completion: { [weak self] result in
            guard let self else { return }
            self.activeDownloads.removeValue(forKey: normalized.mapId)
            switch result {
            case .success:
                let coverage = self.progressByMapId[normalized.mapId]
                    ?? MapOfflinePolicyResolver.coverage(
                        tilesCached: required,
                        tilesRequired: required,
                        policy: policy
                    )
                self.persistProgress(coverage, mapId: normalized.mapId)
                completion(.success(coverage))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        activeDownloads[normalized.mapId] = cancelable
        return cancelable
    }

    public func coverage(
        request: MapOfflinePrefetchRequest,
        styleURI: StyleURI,
        policy: MapOfflinePolicy = .cacheFirst,
        completion: @escaping (Result<MapOfflineCoverage, Error>) -> Void
    ) {
        let normalized: MapOfflinePrefetchRequest
        do {
            normalized = try MapOfflinePolicyResolver.validate(request: request, platform: .nativeMapbox)
        } catch {
            completion(.failure(error))
            return
        }

        if let live = progressByMapId[normalized.mapId] {
            completion(.success(live))
            return
        }
        if let persisted = loadPersistedProgress(mapId: normalized.mapId) {
            completion(.success(persisted))
            return
        }

        let required = MapOfflinePolicyResolver.estimateTileCount(
            bounds: normalized.bounds,
            zoomRange: normalized.zoomRange
        )
        guard let descriptor = Self.makeTilesetDescriptor(
            request: normalized,
            styleURI: styleURI,
            offlineManager: offlineManager
        ) else {
            completion(.failure(GeoKitMapboxOfflineRegionError.invalidLoadOptions))
            return
        }

        tileStore.tileRegionContainsDescriptors(forId: normalized.mapId, descriptors: [descriptor]) { result in
            switch result {
            case .success(let containsAll):
                let cached = containsAll ? required : 0
                let coverage = MapOfflinePolicyResolver.coverage(
                    tilesCached: cached,
                    tilesRequired: required,
                    policy: policy
                )
                completion(.success(coverage))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func cancelPrefetch(mapId: String) {
        activeDownloads.removeValue(forKey: mapId)?.cancel()
    }

    public func removeRegion(mapId: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        cancelPrefetch(mapId: mapId)
        progressByMapId.removeValue(forKey: mapId)
        progressDefaults.removeObject(forKey: progressKeyPrefix + mapId)
        tileStore.removeRegion(forId: mapId) { result in
            switch result {
            case .success:
                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    public static func makeLoadOptions(
        request: MapOfflinePrefetchRequest,
        styleURI: StyleURI,
        offlineManager: OfflineManager
    ) -> TileRegionLoadOptions? {
        guard let descriptor = makeTilesetDescriptor(
            request: request,
            styleURI: styleURI,
            offlineManager: offlineManager
        ) else { return nil }
        let geometry = Geometry.polygon(Self.boundingPolygon(for: request.bounds))
        return TileRegionLoadOptions(
            geometry: geometry,
            descriptors: [descriptor],
            metadata: ["mapId": request.mapId],
            acceptExpired: true
        )
    }

    static func makeTilesetDescriptor(
        request: MapOfflinePrefetchRequest,
        styleURI: StyleURI,
        offlineManager: OfflineManager
    ) -> TilesetDescriptor? {
        let minZoom = UInt8(clamping: request.zoomRange.minZoom)
        let maxZoom = UInt8(clamping: request.zoomRange.maxZoom)
        let options = TilesetDescriptorOptions(
            styleURI: styleURI,
            zoomRange: minZoom ... maxZoom,
            tilesets: nil
        )
        return offlineManager.createTilesetDescriptor(for: options)
    }

    static func boundingPolygon(for bounds: MapOfflineBounds) -> Polygon {
        let ring: [LocationCoordinate2D] = [
            .init(latitude: bounds.south, longitude: bounds.west),
            .init(latitude: bounds.south, longitude: bounds.east),
            .init(latitude: bounds.north, longitude: bounds.east),
            .init(latitude: bounds.north, longitude: bounds.west),
            .init(latitude: bounds.south, longitude: bounds.west),
        ]
        return Polygon([ring])
    }

    private func persistProgress(_ coverage: MapOfflineCoverage, mapId: String) {
        guard let data = try? JSONEncoder().encode(coverage) else { return }
        progressDefaults.set(data, forKey: progressKeyPrefix + mapId)
    }

    private func loadPersistedProgress(mapId: String) -> MapOfflineCoverage? {
        guard let data = progressDefaults.data(forKey: progressKeyPrefix + mapId),
              let coverage = try? JSONDecoder().decode(MapOfflineCoverage.self, from: data)
        else { return nil }
        return coverage
    }
}

#endif
