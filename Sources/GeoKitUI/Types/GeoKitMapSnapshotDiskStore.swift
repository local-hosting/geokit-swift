#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import Foundation
import GeoKitContract
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct GeoKitMapSnapshotDiskRecord: Codable, Sendable, Equatable {
    public var mapId: String
    public var providerId: MapProviderId
    public var cameraFrame: MapCameraFrame
    public var selectedPinId: UUID?
    public var capturedAt: Date
    public var byteLength: Int

    public init(
        mapId: String,
        providerId: MapProviderId,
        cameraFrame: MapCameraFrame,
        selectedPinId: UUID?,
        capturedAt: Date,
        byteLength: Int
    ) {
        self.mapId = mapId
        self.providerId = providerId
        self.cameraFrame = cameraFrame
        self.selectedPinId = selectedPinId
        self.capturedAt = capturedAt
        self.byteLength = byteLength
    }
}

/// PNG snapshot blobs keyed by `mapId` + provider under Application Support.
@MainActor
public final class GeoKitMapSnapshotDiskStore {
    public static let shared = GeoKitMapSnapshotDiskStore()

    private let fileManager: FileManager
    private let directory: URL

    public init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.directory = base.appendingPathComponent("GeoKit/snapshots", isDirectory: true)
        }
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func save(
        mapId: String,
        provider: MapProviderId,
        image: GeoKitPlatformImage,
        cameraFrame: MapCameraFrame,
        selectedPinId: UUID?
    ) throws {
        guard let pngData = image.geoKitPNGData else {
            throw NSError(domain: "GeoKitMapSnapshotDiskStore", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "failed to encode snapshot PNG",
            ])
        }
        if pngData.count > MapOfflineDefaults.snapshotMaxBytesPerMap {
            throw NSError(domain: "GeoKitMapSnapshotDiskStore", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "snapshot exceeds per-map byte budget",
            ])
        }
        let record = GeoKitMapSnapshotDiskRecord(
            mapId: mapId,
            providerId: provider,
            cameraFrame: cameraFrame,
            selectedPinId: selectedPinId,
            capturedAt: Date(),
            byteLength: pngData.count
        )
        try pngData.write(to: imageURL(mapId: mapId, provider: provider), options: .atomic)
        let metaData = try JSONEncoder().encode(record)
        try metaData.write(to: metaURL(mapId: mapId, provider: provider), options: .atomic)
    }

    public func load(
        mapId: String,
        provider: MapProviderId
    ) -> (image: GeoKitPlatformImage, record: GeoKitMapSnapshotDiskRecord)? {
        let imagePath = imageURL(mapId: mapId, provider: provider)
        let metaPath = metaURL(mapId: mapId, provider: provider)
        guard fileManager.fileExists(atPath: imagePath.path),
              fileManager.fileExists(atPath: metaPath.path),
              let pngData = try? Data(contentsOf: imagePath),
              let image = GeoKitSnapshotImageFactory.image(fromPNGData: pngData),
              let metaData = try? Data(contentsOf: metaPath),
              let record = try? JSONDecoder().decode(GeoKitMapSnapshotDiskRecord.self, from: metaData)
        else { return nil }
        return (image, record)
    }

    public func remove(mapId: String, provider: MapProviderId) {
        try? fileManager.removeItem(at: imageURL(mapId: mapId, provider: provider))
        try? fileManager.removeItem(at: metaURL(mapId: mapId, provider: provider))
    }

    public func removeAll() {
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }
        for url in entries {
            try? fileManager.removeItem(at: url)
        }
    }

    private func sanitized(_ mapId: String) -> String {
        mapId.replacingOccurrences(of: "/", with: "_")
    }

    private func baseName(mapId: String, provider: MapProviderId) -> String {
        "\(sanitized(mapId)).\(provider.rawValue)"
    }

    private func imageURL(mapId: String, provider: MapProviderId) -> URL {
        directory.appendingPathComponent("\(baseName(mapId: mapId, provider: provider)).png")
    }

    private func metaURL(mapId: String, provider: MapProviderId) -> URL {
        directory.appendingPathComponent("\(baseName(mapId: mapId, provider: provider)).json")
    }
}

enum GeoKitSnapshotImageFactory {
    static func image(fromPNGData data: Data) -> GeoKitPlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #else
        return nil
        #endif
    }
}

extension GeoKitPlatformImage {
    var geoKitPNGData: Data? {
        #if canImport(UIKit)
        return pngData()
        #elseif canImport(AppKit)
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
#endif
