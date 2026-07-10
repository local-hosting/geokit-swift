#if os(iOS) || os(visionOS)

import CoreLocation
import GeoKitContract
import GeoKitUI
import MapboxMaps
import SwiftUI

/// Mapbox-backed map content for placeholder, snapshot, and live phases.
struct GeoKitMapboxMapContent: View {
    let request: MapContentRequest

    @Environment(\.geokitTransitionSnapshot) private var transitionSnapshot
    @Environment(\.geokitMapIsTransitioning) private var mapIsTransitioning
    @State private var viewport: Viewport = .idle
    @State private var collapsedSnapshot: UIImage?
    @State private var zoomLevel: Float = 12
    @State private var currentZoom: CGFloat = 12
    @State private var isPlusEnabled = true
    @State private var isMinusEnabled = true
    @State private var liveCameraState: CameraState?
    @State private var selectedPinId: UUID?
    @State private var appliedCameraFrame: MapCameraFrame?

    var body: some View {
        phaseContent
            .onAppear {
                seedTransitionSnapshotIfNeeded()
                seedViewportIfNeeded()
                seedSelectedPinIfNeeded()
            }
            .onChange(of: transitionSnapshot) { _, _ in
                seedTransitionSnapshotIfNeeded()
            }
            .onChange(of: request.id) { _, _ in
                resetForCardChange()
            }
            .onChange(of: request.mapProviderId) { _, _ in
                resetForProviderChange()
            }
            .onChange(of: request.cameraFrame) { _, frame in
                guard let frame else { return }
                applyCameraFrame(frame)
            }
            .onChange(of: request.selectedPinId) { _, pinId in
                selectedPinId = pinId
            }
            .preference(key: GeoKitSelectedPinIdKey.self, value: selectedPinId)
    }


    private func seedTransitionSnapshotIfNeeded() {
        guard collapsedSnapshot == nil, let transitionSnapshot else { return }
        collapsedSnapshot = transitionSnapshot
    }

    private func resetForCardChange() {
        appliedCameraFrame = nil
        collapsedSnapshot = nil
        liveCameraState = nil
        seedSelectedPinIfNeeded()
        applyCameraFrame(request.cameraFrame)
    }


    private func resetForProviderChange() {
        collapsedSnapshot = nil
        seedSelectedPinIfNeeded()
        applyCameraFrame(request.cameraFrame)
    }

    private func seedViewportIfNeeded() {
        guard case .idle = viewport else { return }
        applyCameraFrame(request.cameraFrame)
    }

    private func seedSelectedPinIfNeeded() {
        selectedPinId = request.selectedPinId
    }

    private func togglePinSelection(_ pin: MapPin) {
        selectedPinId = selectedPinId == pin.id ? nil : pin.id
    }

    private func applyCameraFrame(_ frame: MapCameraFrame?) {
        var draft = request
        draft.cameraFrame = frame
        let resolved = MapCameraFrameResolver.resolve(for: draft)
        if let appliedCameraFrame, appliedCameraFrame.isApproximatelyEqual(to: resolved) {
            return
        }
        appliedCameraFrame = resolved
        viewport = GeoKitMapViewport.from(resolved)
        zoomLevel = Float(resolved.zoom)
        currentZoom = CGFloat(resolved.zoom)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch request.phase {
        case .placeholder:
            placeholderContent
        case .snapshot:
            GeoKitCollapsedSnapshotView(
                request: request,
                viewport: $viewport,
                snapshot: $collapsedSnapshot
            )
        case .live:
            GeoKitMapSurface(
                request: request,
                viewport: $viewport,
                zoomLevel: $zoomLevel,
                currentZoom: $currentZoom,
                isPlusEnabled: $isPlusEnabled,
                isMinusEnabled: $isMinusEnabled,
                liveCameraState: $liveCameraState,
                selectedPinId: selectedPinId,
                onPinTap: { pin, _ in togglePinSelection(pin) },
                onPinInteractionBegan: {},
                // Fall back to the bridged transition snapshot directly: `collapsedSnapshot` is only seeded in
                // `onAppear`/`onChange`, which SwiftUI defers while `isTransitioning` is true. On the focused center slot
                // handoff that leaves it nil for the live surface's first frames, so the base layer would paint gray
                // ("image then vanishes"). The environment snapshot is available at construction, bridging that gap.
                frozenSnapshot: collapsedSnapshot ?? transitionSnapshot
            )
        }
    }

    private var placeholderContent: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground
            Text(request.title)
                .font(GeoKitMapTheme.placeholderTitleFont)
                .foregroundStyle(.secondary)
        }
    }
}

private extension MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
#endif
