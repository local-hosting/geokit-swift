import Foundation

public enum MapStage: String, Sendable, Equatable {
    case peek
    case center
    case expand
}

public struct MapStagePolicy: Sendable, Equatable {
    public var allowsLiveRendering: Bool
    public var allowsSnapshotCapture: Bool
    public var stage: MapStage

    public init(stage: MapStage, isExpanded: Bool) {
        self.stage = stage
        switch stage {
        case .peek:
            allowsLiveRendering = false
            allowsSnapshotCapture = false
        case .center:
            allowsLiveRendering = true
            allowsSnapshotCapture = true
        case .expand:
            allowsLiveRendering = true
            allowsSnapshotCapture = isExpanded
        }
    }
}

public enum MapStagePolicyResolver {
    public static func resolve(isCentered: Bool, isExpanded: Bool) -> MapStagePolicy {
        if isExpanded {
            return MapStagePolicy(stage: .expand, isExpanded: true)
        }
        if isCentered {
            return MapStagePolicy(stage: .center, isExpanded: false)
        }
        return MapStagePolicy(stage: .peek, isExpanded: false)
    }
}
