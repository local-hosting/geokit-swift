import CardMediaContract
import CoreGraphics
import Foundation

// MARK: - Slot role + mode (GeoKit names)

public typealias GeoKitCardSlotRole = CardMediaSlotRole
public typealias GeoKitCardMediaMode = CardMediaMode

public enum GeoKitCardSlotRoleResolver {
    public static func role(
        isCentered: Bool,
        stackOffset: CGFloat,
        collectionExpanded: Bool,
        isCollapsing: Bool,
        isExpandedOverlay: Bool,
        peekRadius: Int = GeoKitMapCardStageConstants.peekRadius
    ) -> GeoKitCardSlotRole {
        CardMediaSlotRoleResolver.role(
            isCentered: isCentered,
            stackOffset: stackOffset,
            collectionExpanded: collectionExpanded,
            isCollapsing: isCollapsing,
            isExpandedOverlay: isExpandedOverlay,
            peekRadius: peekRadius
        )
    }
}

public enum GeoKitCardMediaModeResolver {
    public static func resolve(
        role: GeoKitCardSlotRole,
        isLiveEnabled: Bool,
        isMapRendered: Bool,
        hasSnapshot: Bool,
        isTransitioning: Bool
    ) -> GeoKitCardMediaMode {
        CardMediaModeResolver.resolve(
            role: role,
            isLiveEnabled: isLiveEnabled,
            isLiveContentRendered: isMapRendered,
            hasSnapshot: hasSnapshot,
            isTransitioning: isTransitioning
        )
    }
}

public enum GeoKitCardPresentationBridge {
    public static func presentationContext(
        role: GeoKitCardSlotRole,
        stackOffset: CGFloat,
        collectionExpanded: Bool,
        isTransitioning: Bool,
        isCollapsing: Bool,
        isLiveEnabled: Bool,
        isMapRendered: Bool,
        hasActiveSnapshot: Bool,
        isCenteredInStack: Bool
    ) -> MapCardMediaPresentationContext {
        CardMediaPresentationBridge.presentationContext(
            role: role,
            stackOffset: stackOffset,
            collectionExpanded: collectionExpanded,
            isTransitioning: isTransitioning,
            isCollapsing: isCollapsing,
            isLiveEnabled: isLiveEnabled,
            isLiveContentRendered: isMapRendered,
            hasActiveSnapshot: hasActiveSnapshot,
            isCenteredInStack: isCenteredInStack
        )
    }
}
