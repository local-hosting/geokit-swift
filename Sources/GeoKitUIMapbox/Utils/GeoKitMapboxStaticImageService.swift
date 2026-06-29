#if os(iOS)
import CoreLocation
import Foundation
import GeoKitContract
import MapboxMaps
import UIKit

/// Fetches a flat map image from the Mapbox Static Images API over HTTP.
///
/// Back/fan cards use this path so they never run the GPU ``Snapshotter`` and therefore
/// never contend with the live Metal map on the front card. Markers are intentionally
/// omitted — only the live front card draws pins.
enum GeoKitMapboxStaticImageService {
    private static let maxDimension = 1280

    enum CaptureError: Error, CustomStringConvertible {
        case invalidSize(CGSize)
        case missingAccessToken
        case invalidStyleURI(String)
        case urlConstruction
        case httpError(Int)
        case imageDecoding

        var description: String {
            switch self {
            case .invalidSize(let s): "invalid capture size \(s)"
            case .missingAccessToken: "Mapbox access token is empty — set MapboxOptions.accessToken or MBXAccessToken in Info.plist"
            case .invalidStyleURI(let uri): "could not parse Mapbox style URI: \(uri)"
            case .urlConstruction: "failed to construct Static Images API URL"
            case .httpError(let code): "Mapbox Static Images API returned HTTP \(code)"
            case .imageDecoding: "response data could not be decoded as UIImage"
            }
        }
    }

    static func capture(request: MapContentRequest, size: CGSize) async throws -> UIImage {
        guard size.width >= 1, size.height >= 1 else {
            throw CaptureError.invalidSize(size)
        }
        let token = accessToken()
        guard !token.isEmpty else {
            throw CaptureError.missingAccessToken
        }
        guard let style = StyleReference(styleURI: request.mapStyleURI) else {
            throw CaptureError.invalidStyleURI(request.mapStyleURI)
        }

        let frame = MapCameraFrameResolver.resolve(for: request)
        let center = CLLocationCoordinate2D(latitude: frame.centerLatitude, longitude: frame.centerLongitude)
        let zoom = frame.zoom
        let bearing = frame.bearing
        let pitch = frame.pitch

        let width = min(max(Int(size.width.rounded()), 1), maxDimension)
        let height = min(max(Int(size.height.rounded()), 1), maxDimension)

        let camera = String(
            format: "%.6f,%.6f,%.2f,%.2f,%.2f",
            center.longitude, center.latitude, zoom, bearing, pitch
        )

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.mapbox.com"
        components.path = "/styles/v1/\(style.username)/\(style.styleId)/static/\(camera)/\(width)x\(height)@2x"
        components.queryItems = [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "attribution", value: "false"),
            URLQueryItem(name: "logo", value: "false")
        ]
        guard let url = components.url else {
            throw CaptureError.urlConstruction
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            throw CaptureError.httpError(status)
        }
        guard let image = UIImage(data: data) else {
            throw CaptureError.imageDecoding
        }
        return image
    }

    private static func resolvedCenter(for request: MapContentRequest) -> CLLocationCoordinate2D {
        if let frame = request.cameraFrame {
            return CLLocationCoordinate2D(latitude: frame.centerLatitude, longitude: frame.centerLongitude)
        }
        if let first = request.pins.first {
            return CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    private static func accessToken() -> String {
        let token = MapboxOptions.accessToken
        if !token.isEmpty { return token }
        return (Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String) ?? ""
    }

    private struct StyleReference {
        let username: String
        let styleId: String

        init?(styleURI: String) {
            var path = styleURI
            let prefix = "mapbox://styles/"
            if path.hasPrefix(prefix) {
                path.removeFirst(prefix.count)
            }
            let parts = path.split(separator: "/").map(String.init)
            guard parts.count >= 2 else { return nil }
            username = parts[0]
            styleId = parts[1]
        }
    }
}
#endif
