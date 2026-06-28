#if os(iOS)
import AccordDesignSystem
import CardMediaContract
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Positions one persistent live map to the active card's reported media-surface frame.
struct GeoKitCardMapLiveHost<Card: GeoKitLiveMapCard & AXCardItem>: View {
    let entries: [AXCardMediaSurfaceFramePreferenceKey.Entry]
    @ObservedObject var collection: AXCardCollectionModel<Card>
    @ObservedObject var coordinator: GeoKitCardMapCoordinator<Card>

    private var liveCard: Card? {
        coordinator.centerCard(in: collection.cards)
    }

    private var mapIsTransitioning: Bool {
        collection.isTransitioning || collection.isCollapsing
    }

    private func entry(for card: Card) -> AXCardMediaSurfaceFramePreferenceKey.Entry? {
        guard let match = entries.first(where: { $0.cardID == card.id }),
              match.frame.width > 1,
              match.frame.height > 1
        else { return nil }
        return match
    }

    var body: some View {
        GeometryReader { geo in
            let hostOrigin = geo.frame(in: .global).origin
            if (collection.isExpanded || collection.isCollapsing || collection.isTransitioning), let card = liveCard, let entry = entry(for: card) {
                GeoKitInCardLiveMapBody(
                    cameraStore: coordinator.cameraStore,
                    card: card,
                    isExpanded: collection.isExpanded,
                    mapProviderId: coordinator.provider,
                    mapIsTransitioning: mapIsTransitioning
                )
                .id(card.id)
                .frame(width: entry.frame.width, height: entry.frame.height)
                .clipShape(
                    RoundedRectangle(cornerRadius: entry.cornerRadius ?? 0, style: .continuous)
                )
                .position(
                    x: entry.frame.midX - hostOrigin.x,
                    y: entry.frame.midY - hostOrigin.y
                )
            }
        }
        .allowsHitTesting(collection.isExpanded)
        .accessibilityIdentifier("geokit.card-map-live-host")
    }
}

private struct GeoKitCardMapHostModifier<
    Card: GeoKitLiveMapCard & AXCardItem,
    Collection: AXCardCollectionModel<Card>
>: ViewModifier {
    @ObservedObject var coordinator: GeoKitCardMapCoordinator<Card>
    @ObservedObject var collection: Collection
    let layout: CardMediaCollectionLayout
    var mediaContentSize: () -> CGSize
    var skipSnapshotCapture: () -> Bool
    var onAppear: (() -> Void)?

    private var shouldRevealCollection: Bool {
        if skipSnapshotCapture() { return true }
        if !coordinator.mediaStore.hidesStackUntilInitialCenterPeekReady { return true }
        if coordinator.mediaStore.hasRevealedCardStack { return true }
        return coordinator.mediaStore.isInitialCenterPeekReady
    }

    func body(content: Content) -> some View {
        content
            .opacity(shouldRevealCollection ? 1 : 0)
            .allowsHitTesting(shouldRevealCollection)
            .animation(.easeOut(duration: 0.12), value: shouldRevealCollection)
            .environmentObject(coordinator)
            .environmentObject(coordinator.cameraStore)
            .environmentObject(coordinator.mediaStore)
            .backgroundPreferenceValue(AXCardMediaSurfaceFramePreferenceKey.self) { entries in
                GeoKitCardMapLiveHost(
                    entries: entries,
                    collection: collection,
                    coordinator: coordinator
                )
            }
            .onAppear {
                coordinator.bind(
                    collection: collection,
                    layout: layout,
                    skipSnapshotCapture: skipSnapshotCapture
                )
                onAppear?()
            }
            .onDisappear {
                coordinator.unbind()
            }
            .axCardMediaLoadCoordination(
                coordinator.loadCoordinator,
                collection: collection,
                layout: layout,
                mediaContentSize: mediaContentSize()
            )
    }
}

public extension View {
    /// Installs map media plugin coordination and the persistent expanded live-map host.
    func geoKitCardMapHost<Card: GeoKitLiveMapCard & AXCardItem, Collection: AXCardCollectionModel<Card>>(
        coordinator: GeoKitCardMapCoordinator<Card>,
        collection: Collection,
        layout: CardMediaCollectionLayout = .stack,
        mediaContentSize: @escaping () -> CGSize = { .zero },
        skipSnapshotCapture: @escaping () -> Bool = { false },
        onAppear: (() -> Void)? = nil
    ) -> some View {
        modifier(
            GeoKitCardMapHostModifier(
                coordinator: coordinator,
                collection: collection,
                layout: layout,
                mediaContentSize: mediaContentSize,
                skipSnapshotCapture: skipSnapshotCapture,
                onAppear: onAppear
            )
        )
    }
}
#endif
