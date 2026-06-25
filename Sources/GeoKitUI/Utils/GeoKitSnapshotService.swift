#if os(iOS)
@_spi(Restricted) import MapboxMaps
import GeoKitContract
import UIKit

/// Serializes Mapbox snapshot capture; front-card work preempts background peek captures.
actor GeoKitSnapshotCaptureQueue {
    static let shared = GeoKitSnapshotCaptureQueue()

    private struct Job: Identifiable {
        let id = UUID()
        let priority: MapSnapshotPriority
        let viewport: Viewport
        let size: CGSize
        let styleURI: String
        let continuation: CheckedContinuation<UIImage?, Never>
    }

    private var pending: [Job] = []
    private var activeJob: Job?
    private var activeTask: Task<Void, Never>?

    func capture(
        viewport: Viewport,
        size: CGSize,
        styleURI: String,
        priority: MapSnapshotPriority
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let job = Job(
                priority: priority,
                viewport: viewport,
                size: size,
                styleURI: styleURI,
                continuation: continuation
            )
            enqueue(job)
        }
    }

    private func enqueue(_ job: Job) {
        pending.append(job)
        pending.sort { $0.priority > $1.priority }

        if job.priority == .top {
            preemptBackgroundCaptureIfNeeded()
        }
        startNextIfIdle()
    }

    private func preemptBackgroundCaptureIfNeeded() {
        guard let activeJob, activeJob.priority == .background else { return }
        activeTask?.cancel()
        self.activeJob = nil
        self.activeTask = nil
    }

    private func startNextIfIdle() {
        guard activeJob == nil, !pending.isEmpty else { return }
        let job = pending.removeFirst()
        activeJob = job
        activeTask = Task {
            let image = await Self.performCapture(job: job)
            guard !Task.isCancelled else {
                finish(job: job, image: nil, requeueOnCancel: job.priority == .background)
                return
            }
            finish(job: job, image: image, requeueOnCancel: false)
        }
    }

    private func finish(job: Job, image: UIImage?, requeueOnCancel: Bool) {
        if requeueOnCancel {
            pending.append(job)
            pending.sort { $0.priority > $1.priority }
        } else {
            job.continuation.resume(returning: image)
        }
        if activeJob?.id == job.id {
            activeJob = nil
            activeTask = nil
            startNextIfIdle()
        }
    }

    private static func performCapture(job: Job) async -> UIImage? {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: job.size),
              let camera = cameraOptions(for: job.viewport),
              let style = StyleURI(rawValue: job.styleURI)
        else { return nil }

        do {
            try await GeoKitMapboxLiveMapRegistry.waitUntilSafeForSnapshot()
        } catch {
            return nil
        }

        if Task.isCancelled { return nil }
        return await captureOnMain(size: job.size, camera: camera, style: style)
    }

    @MainActor
    private static func captureOnMain(size: CGSize, camera: CameraOptions, style: StyleURI) async -> UIImage? {
        GeoKitMapBootstrap.prepareMapbox()
        let scale = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen.scale ?? UITraitCollection.current.displayScale
        let options = GeoKitMapTokens.snapshotOptions(size: size, pixelRatio: scale)
        let snapshotter = Snapshotter(options: options)
        snapshotter.styleURI = style
        snapshotter.setCamera(to: camera)

        return await withCheckedContinuation { continuation in
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
                try? await Task.sleep(for: .seconds(12))
                finish(nil)
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

enum GeoKitSnapshotService {
    static func capture(
        viewport: Viewport,
        size: CGSize,
        styleURI: String,
        priority: MapSnapshotPriority = .background
    ) async -> UIImage? {
        await GeoKitSnapshotCaptureQueue.shared.capture(
            viewport: viewport,
            size: size,
            styleURI: styleURI,
            priority: priority
        )
    }
}
#endif
