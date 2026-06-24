import Foundation

public enum MapContentPhase: String, Sendable, Equatable {
    case placeholder
    case snapshot
    case live
}

public struct MapContentRequest: Sendable, Equatable {
    public var cardID: String
    public var phase: MapContentPhase
    public var isExpanded: Bool

    public init(cardID: String, phase: MapContentPhase, isExpanded: Bool) {
        self.cardID = cardID
        self.phase = phase
        self.isExpanded = isExpanded
    }
}
