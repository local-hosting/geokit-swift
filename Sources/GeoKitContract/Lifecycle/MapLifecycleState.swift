import Foundation

public struct MapLifecycleState: Sendable, Equatable {
    public var hasSnapshot: Bool
    public var isStyleReady: Bool
    public var isSurfaceReady: Bool
    public var isTransitioning: Bool

    public init(
        hasSnapshot: Bool = false,
        isStyleReady: Bool = false,
        isSurfaceReady: Bool = true,
        isTransitioning: Bool = false
    ) {
        self.hasSnapshot = hasSnapshot
        self.isStyleReady = isStyleReady
        self.isSurfaceReady = isSurfaceReady
        self.isTransitioning = isTransitioning
    }
}
