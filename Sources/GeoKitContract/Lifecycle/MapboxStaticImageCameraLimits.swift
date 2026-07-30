import Foundation

/// Mapbox Static Images API camera limits — live Mapbox GL can exceed these; HTTP static must not.
public enum MapboxStaticImageCameraLimits {
    public static let minPitch: Double = 0
    public static let maxPitch: Double = 60

    /// Clamp pitch to 0…60 and normalize bearing to 0..<360 for the Static Images URL path.
    public static func clamped(forStaticImages frame: MapCameraFrame) -> MapCameraFrame {
        var bearing = frame.bearing.truncatingRemainder(dividingBy: 360)
        if bearing < 0 { bearing += 360 }
        let pitch = min(max(frame.pitch, minPitch), maxPitch)
        return MapCameraFrame(
            centerLatitude: frame.centerLatitude,
            centerLongitude: frame.centerLongitude,
            zoom: frame.zoom,
            bearing: bearing,
            pitch: pitch
        )
    }
}
