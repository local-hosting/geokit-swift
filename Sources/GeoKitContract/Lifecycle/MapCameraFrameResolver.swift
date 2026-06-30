import Foundation

/// Derives the provider-neutral camera a map request will render — shared by Mapbox and MapKit.
public enum MapCameraFrameResolver {
    /// Collapsed card peeks — flat camera keeps Mapbox style symbol layers (e.g. transit) visible on live GL.
    public static let collapsedPitch: Double = 0
    /// Expanded hero — pitched 3D framing.
    public static let expandedPitch: Double = 50
    /// Backward-compatible alias for expanded pitch.
    public static let defaultPitch: Double = expandedPitch

    /// The camera is the camera: honor the request's real camera verbatim — no pitch flattening, no pin-anchor
    /// substitution. The seed below is only for internal requests that never carried a camera; map cards
    /// always declare one up front, so it never fabricates a card's view.
    public static func resolve(for request: MapContentRequest) -> MapCameraFrame {
        if let cameraFrame = request.cameraFrame {
            return cameraFrame
        }
        return initialFrame(
            pins: request.pins,
            preferredZoom: request.preferredZoom,
            isExpanded: request.isExpanded
        )
    }

    /// Whether the live camera has arrived at its target (the card's declared/persisted camera). Used to hold
    /// the cold-load cover through the fly-to: the style's far-away default camera isn't approximately equal to
    /// the target, so the cover stays up until the map settles on the real camera.
    public static func isCameraSettledAtTarget(
        _ current: MapCameraFrame?,
        target: MapCameraFrame
    ) -> Bool {
        guard let current else { return false }
        return current.isApproximatelyEqual(to: target)
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
