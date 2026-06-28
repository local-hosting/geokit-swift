#if os(iOS)
import GeoKitContract
import SwiftUI

private struct GeoKitSelfManagedMapMediaTaskID: Hashable {
    let cardID: String
    let generation: UInt
    let provider: MapProviderId
    let width: Int
    let height: Int
    let isCentered: Bool
    let loadAllowed: Bool
    let selectedPinId: UUID?
}

public extension View {
    /// Per-card static snapshot load keyed to card identity, provider, size, and center state.
    /// Center cards capture first, then `onPromoteToLive` runs so only one live map mounts.
    func geokitSelfManagedMapMedia(
        card: any GeoKitMapSnapshotCard,
        isCentered: Bool,
        provider: MapProviderId,
        mapSize: CGSize,
        generation: UInt,
        loadAllowed: Bool,
        cameraFrame: MapCameraFrame? = nil,
        controller: GeoKitCardMapMediaController = .shared,
        onLoadingChanged: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        modifier(
            GeoKitSelfManagedMapMediaModifier(
                card: card,
                isCentered: isCentered,
                provider: provider,
                mapSize: mapSize,
                generation: generation,
                loadAllowed: loadAllowed,
                cameraFrame: cameraFrame,
                controller: controller,
                onLoadingChanged: onLoadingChanged
            )
        )
    }
}

private struct GeoKitSelfManagedMapMediaModifier: ViewModifier {
    let card: any GeoKitMapSnapshotCard
    let isCentered: Bool
    let provider: MapProviderId
    let mapSize: CGSize
    let generation: UInt
    let loadAllowed: Bool
    let cameraFrame: MapCameraFrame?
    let controller: GeoKitCardMapMediaController
    let onLoadingChanged: (Bool) -> Void

    private var taskID: GeoKitSelfManagedMapMediaTaskID {
        let request = card.mapSnapshotRequest(provider: provider, cameraFrame: cameraFrame)
        return GeoKitSelfManagedMapMediaTaskID(
            cardID: card.id,
            generation: generation,
            provider: provider,
            width: Int(mapSize.width.rounded()),
            height: Int(mapSize.height.rounded()),
            isCentered: isCentered,
            loadAllowed: loadAllowed,
            selectedPinId: request.selectedPinId
        )
    }

    func body(content: Content) -> some View {
        content
            .task(id: taskID) {
                guard loadAllowed else { return }
                guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapSize) else { return }
                await controller.ensureStaticSnapshot(
                    for: card,
                    size: mapSize,
                    provider: provider,
                    priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                    cameraFrame: cameraFrame,
                    onLoadingChanged: onLoadingChanged
                )
            }
    }
}
#endif
