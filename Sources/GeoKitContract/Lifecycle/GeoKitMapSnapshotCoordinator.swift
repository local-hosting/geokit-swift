import CoreGraphics
import Foundation

/// Provider-aware snapshot queue for card peek windows — Mapbox defers until live map unmounts; MapKit may capture immediately.
@MainActor
public final class GeoKitMapSnapshotCoordinator {
    public struct PendingCapture: Equatable, Sendable {
        public var requestID: String
        public var size: CGSize
        public var provider: MapProviderId

        public init(requestID: String, size: CGSize, provider: MapProviderId) {
            self.requestID = requestID
            self.size = size
            self.provider = provider
        }
    }

    public private(set) var pendingCaptures: [PendingCapture] = []
    public private(set) var completedCaptureCount = 0

    public var captureHandler: (@Sendable (MapContentRequest, CGSize) async -> Bool)?

    public init() {}

    public func resetForTesting() {
        pendingCaptures.removeAll()
        completedCaptureCount = 0
        captureHandler = nil
    }

    public func schedule(request: MapContentRequest, size: CGSize, liveMapActive: Bool) {
        let provider = request.mapProviderId ?? .mapbox
        if MapSnapshotCaptureGate.shouldDeferCapture(provider: provider, liveMapActive: liveMapActive) {
            pendingCaptures.removeAll { $0.requestID == request.id }
            pendingCaptures.append(
                PendingCapture(requestID: request.id, size: size, provider: provider)
            )
            return
        }
        Task {
            await performCapture(request: request, size: size)
        }
    }

    public func flushPending(liveMapActive: Bool) async {
        guard !liveMapActive else { return }
        let batch = pendingCaptures
        pendingCaptures.removeAll()
        for item in batch {
            let request = MapContentRequest(
                id: item.requestID,
                phase: .snapshot,
                isExpanded: false,
                mapProviderId: item.provider
            )
            await performCapture(request: request, size: item.size)
        }
    }

    private func performCapture(request: MapContentRequest, size: CGSize) async {
        guard let captureHandler else { return }
        if await captureHandler(request, size) {
            completedCaptureCount += 1
        }
    }
}
