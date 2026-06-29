import CoreGraphics
import Foundation

/// Decides when a frozen peek snapshot must be recaptured.
public enum MapSnapshotStalenessPolicy {
    public static let layoutDimensionTolerance: Double = 1

    public static func metadata(
        for request: MapContentRequest,
        layoutSize: CGSize
    ) -> MapSnapshotCaptureMetadata {
        MapSnapshotCaptureMetadata(
            cameraFrame: MapCameraFrameResolver.resolve(for: request),
            layoutWidth: layoutSize.width,
            layoutHeight: layoutSize.height,
            mapStyleURI: request.mapStyleURI,
            pins: request.pins,
            selectedPinId: request.selectedPinId
        )
    }

    public static func isStale(
        stored: MapSnapshotCaptureMetadata?,
        request: MapContentRequest,
        layoutSize: CGSize
    ) -> Bool {
        guard let stored else { return true }
        let current = metadata(for: request, layoutSize: layoutSize)
        if stored.mapStyleURI != current.mapStyleURI { return true }
        if stored.pins != current.pins { return true }
        if stored.selectedPinId != current.selectedPinId { return true }
        if layoutSizeChanged(stored: stored, current: current) { return true }
        if !stored.cameraFrame.isApproximatelyEqual(to: current.cameraFrame) { return true }
        return false
    }

    private static func layoutSizeChanged(
        stored: MapSnapshotCaptureMetadata,
        current: MapSnapshotCaptureMetadata
    ) -> Bool {
        abs(stored.layoutWidth - current.layoutWidth) > layoutDimensionTolerance
            || abs(stored.layoutHeight - current.layoutHeight) > layoutDimensionTolerance
    }
}
