#if os(iOS)
import Foundation
import Network

/// Event-driven network reachability — no polling; resumes waiters when path becomes satisfied.
@MainActor
public final class GeoKitReachabilityMonitor {
    public static let shared = GeoKitReachabilityMonitor()

    private(set) public var isOnline = true

    private var monitor: NWPathMonitor?
    private var satisfiedHandlers: [UUID: @MainActor () -> Void] = [:]

    private init() {}

    public func start() {
        guard monitor == nil else { return }
        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "GeoKitReachabilityMonitor"))
        monitor = pathMonitor
    }

    public func stop() {
        monitor?.cancel()
        monitor = nil
    }

    @discardableResult
    public func onBecameSatisfied(_ handler: @escaping @MainActor () -> Void) -> UUID {
        let id = UUID()
        satisfiedHandlers[id] = handler
        if isOnline {
            handler()
        }
        return id
    }

    public func removeHandler(_ id: UUID) {
        satisfiedHandlers.removeValue(forKey: id)
    }

    public func waitUntilOnline() async {
        guard !isOnline else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let id = UUID()
            satisfiedHandlers[id] = {
                self.removeHandler(id)
                continuation.resume()
            }
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied
        guard !wasOnline, isOnline else { return }
        let handlers = Array(satisfiedHandlers.values)
        for handler in handlers {
            handler()
        }
    }

    public func resetForTesting() {
        stop()
        isOnline = true
        satisfiedHandlers.removeAll()
    }
}
#endif
