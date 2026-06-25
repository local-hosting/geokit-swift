@_spi(Restricted) import MapboxMaps
import UIKit

enum GeoKitSnapshotService {
    private static let captureTimeout: Duration = .seconds(12)

    static func capture(viewport: Viewport, size: CGSize, styleURI: String) async -> UIImage? {
        guard size.width >= GeoKitMapLayout.minMapSize,
              size.height >= GeoKitMapLayout.minMapSize,
              let camera = cameraOptions(for: viewport),
              let style = StyleURI(rawValue: styleURI)
        else { return nil }

        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let scale = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .screen.scale ?? UITraitCollection.current.displayScale
                let options = GeoKitMapTokens.snapshotOptions(size: size, pixelRatio: scale)
                let snapshotter = Snapshotter(options: options)
                snapshotter.styleURI = style
                snapshotter.setCamera(to: camera)

                var finished = false
                var styleObserver: AnyCancelable?

                func finish(_ image: UIImage?) {
                    guard !finished else { return }
                    finished = true
                    styleObserver?.cancel()
                    continuation.resume(returning: image)
                }

                styleObserver = snapshotter.onStyleLoaded.observe { _ in
                    snapshotter.start(overlayHandler: nil) { result in
                        switch result {
                        case .success(let image):
                            finish(image)
                        case .failure:
                            finish(nil)
                        }
                    }
                }

                Task {
                    try? await Task.sleep(for: captureTimeout)
                    finish(nil)
                }
            }
        }
    }

    private static func cameraOptions(for viewport: Viewport) -> CameraOptions? {
        guard let camera = viewport.camera else { return nil }
        return CameraOptions(
            center: camera.center,
            zoom: camera.zoom,
            bearing: camera.bearing,
            pitch: camera.pitch
        )
    }
}
