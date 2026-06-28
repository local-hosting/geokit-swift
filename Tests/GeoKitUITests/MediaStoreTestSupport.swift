#if canImport(UIKit) || canImport(AppKit)
import CoreGraphics
import GeoKitContract
@testable import GeoKitUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Minimal 1×1 bitmap for fake captures — content is irrelevant, only presence matters.
@MainActor
func makeTestSnapshotImage() -> GeoKitPlatformImage {
    #if canImport(AppKit)
    return NSImage(size: NSSize(width: 1, height: 1))
    #else
    return UIImage()
    #endif
}

/// Stand-in card that owns a real snapshot cache so `hasUsableSnapshot` reflects fake captures.
@MainActor
class FakeSnapshotCard: GeoKitMapSnapshotCard {
    let id: String
    let mapProviderSnapshotCache = GeoKitMapProviderSnapshotCache()

    init(id: String) {
        self.id = id
    }

    func mapSnapshotRequest(provider: MapProviderId, cameraFrame: MapCameraFrame?) -> MapContentRequest {
        MapContentRequest(id: id, phase: .snapshot, isExpanded: false)
    }
}

/// Live-capable fake card for drag-warm handoff tests.
@MainActor
final class FakeLiveSnapshotCard: FakeSnapshotCard, GeoKitLiveMapCard, ObservableObject {
    @Published var selectedPinId: UUID?
    private var renderedProviders: Set<MapProviderId> = []

    override init(id: String) {
        super.init(id: id)
    }

    func isMapRendered(for provider: MapProviderId) -> Bool {
        renderedProviders.contains(provider)
    }

    func setMapRendered(_ rendered: Bool, for provider: MapProviderId) {
        if rendered {
            renderedProviders.insert(provider)
        } else {
            renderedProviders.remove(provider)
        }
    }

    func clearMapRendered() {
        renderedProviders.removeAll()
    }

    func liveMapRequest(
        isExpanded: Bool,
        mapProviderId: MapProviderId,
        cameraFrame: MapCameraFrame?
    ) -> MapContentRequest {
        MapContentRequest(id: id, phase: .live, isExpanded: isExpanded)
    }
}

/// Records capture order + priority and writes a snapshot into the card cache, like the real controller.
@MainActor
final class FakeSnapshotController: GeoKitMapSnapshotControlling {
    private(set) var captureOrder: [String] = []
    private(set) var priorityByCard: [String: MapSnapshotPriority] = [:]
    private(set) var matchesLiveViewportByCard: [String: Bool] = [:]
    private let captureFrame = MapCameraFrame(centerLatitude: 1, centerLongitude: 2, zoom: 12)

    func captureCount(for id: String) -> Int {
        captureOrder.filter { $0 == id }.count
    }

    func ensureStaticSnapshot(
        for card: any GeoKitMapSnapshotCard,
        size: CGSize,
        provider: MapProviderId,
        priority: MapSnapshotPriority,
        cameraFrame: MapCameraFrame?,
        onLoadingChanged: ((Bool) -> Void)?,
        forceRecapture: Bool,
        matchesLiveViewport: Bool
    ) async {
        captureOrder.append(card.id)
        priorityByCard[card.id] = priority
        matchesLiveViewportByCard[card.id] = matchesLiveViewport
        onLoadingChanged?(true)
        card.setMapSnapshotSize(size, for: provider)
        card.setFrozenSnapshot(
            makeTestSnapshotImage(),
            for: provider,
            cameraFrame: cameraFrame ?? captureFrame
        )
        onLoadingChanged?(false)
    }
}

/// Lets queued `Task` work on the main actor run to completion before assertions.
@MainActor
func settle(iterations: Int = 50) async {
    for _ in 0..<iterations {
        await Task.yield()
    }
}
#endif
