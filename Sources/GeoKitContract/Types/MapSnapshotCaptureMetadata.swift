import Foundation

/// Fingerprint of the inputs used to produce a frozen map peek snapshot.
public struct MapSnapshotCaptureMetadata: Sendable, Equatable {
    public var cameraFrame: MapCameraFrame
    public var layoutWidth: Double
    public var layoutHeight: Double
    public var mapStyleURI: String
    public var pins: [MapPin]
    public var selectedPinId: UUID?

    public init(
        cameraFrame: MapCameraFrame,
        layoutWidth: Double,
        layoutHeight: Double,
        mapStyleURI: String,
        pins: [MapPin],
        selectedPinId: UUID?
    ) {
        self.cameraFrame = cameraFrame
        self.layoutWidth = layoutWidth
        self.layoutHeight = layoutHeight
        self.mapStyleURI = mapStyleURI
        self.pins = pins
        self.selectedPinId = selectedPinId
    }
}
