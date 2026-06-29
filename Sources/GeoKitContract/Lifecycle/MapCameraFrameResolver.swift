import Foundation

/// Derives the provider-neutral camera a map request will render — shared by Mapbox and MapKit.
public enum MapCameraFrameResolver {
    /// Collapsed card peeks — flat camera keeps Mapbox style symbol layers (e.g. transit) visible on live GL.
    public static let collapsedPitch: Double = 0
    /// Expanded hero — pitched 3D framing.
    public static let expandedPitch: Double = 50
    /// Backward-compatible alias for expanded pitch.
    public static let defaultPitch: Double = expandedPitch

    public static func resolve(for request: MapContentRequest) -> MapCameraFrame {
        let frame: MapCameraFrame
        if let cameraFrame = storedFrameIfNearPins(request.cameraFrame, pins: request.pins) {
            frame = cameraFrame
        } else {
            frame = initialFrame(
                pins: request.pins,
                preferredZoom: request.preferredZoom,
                isExpanded: request.isExpanded
            )
        }
        return frameWithStyleLabelPitch(frame)
    }

    /// Mapbox Standard transit and POI symbol layers drop out under pitched cameras on live GL.
    private static func frameWithStyleLabelPitch(_ frame: MapCameraFrame) -> MapCameraFrame {
        var flattened = frame
        flattened.pitch = collapsedPitch
        return flattened
    }

    /// Rejects persisted/style-default cameras that drift far from the card's pin anchor.
    public static func storedFrameIfNearPins(
        _ stored: MapCameraFrame?,
        pins: [MapPin],
        maxCenterDeltaDegrees: Double = 1.0
    ) -> MapCameraFrame? {
        guard let stored else { return nil }
        guard !pins.isEmpty else { return stored }
        let anchor = centerCoordinate(from: pins) ?? defaultCenter(from: pins)
        let latDelta = abs(stored.centerLatitude - anchor.latitude)
        let lonDelta = abs(stored.centerLongitude - anchor.longitude)
        guard latDelta <= maxCenterDeltaDegrees, lonDelta <= maxCenterDeltaDegrees else {
            return nil
        }
        return stored
    }

    public static func initialFrame(
        pins: [MapPin],
        preferredZoom: Double,
        isExpanded: Bool = false
    ) -> MapCameraFrame {
        let center = centerCoordinate(from: pins) ?? defaultCenter(from: pins)
        return MapCameraFrame(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            zoom: preferredZoom,
            bearing: 0,
            pitch: collapsedPitch
        )
    }

    private static func centerCoordinate(from pins: [MapPin]) -> (latitude: Double, longitude: Double)? {
        guard !pins.isEmpty else { return nil }
        let lats = pins.map(\.latitude)
        let lons = pins.map(\.longitude)
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max()
        else {
            return nil
        }
        return (
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }

    private static func defaultCenter(from pins: [MapPin]) -> (latitude: Double, longitude: Double) {
        if let first = pins.first {
            return (first.latitude, first.longitude)
        }
        return (0, 0)
    }
}
