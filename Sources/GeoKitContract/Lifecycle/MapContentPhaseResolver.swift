import Foundation

public struct MapLifecycleInput: Sendable, Equatable {
    public var policy: MapStagePolicy
    public var lifecycle: MapLifecycleState

    public init(policy: MapStagePolicy, lifecycle: MapLifecycleState) {
        self.policy = policy
        self.lifecycle = lifecycle
    }
}

public enum MapContentPhaseResolver {
    /// Resolve placeholder / snapshot / live phase from host composition policy and runtime readiness.
    public static func resolve(_ input: MapLifecycleInput) -> MapContentPhase {
        guard input.lifecycle.isSurfaceReady else { return .placeholder }

        if !input.policy.allowsLiveRendering {
            return input.lifecycle.hasSnapshot ? .snapshot : .placeholder
        }

        if input.lifecycle.isTransitioning, input.lifecycle.hasSnapshot {
            return .snapshot
        }

        if !input.lifecycle.isStyleReady, input.lifecycle.hasSnapshot {
            return .snapshot
        }

        return .live
    }
}
