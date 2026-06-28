#if os(iOS)
import AccordDesignSystem
import CardMediaContract
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Positions one persistent live map to the active card's reported media-surface frame.
private struct GeoKitMapLiveHost<Card: GeoKitLiveMapCard & AXCardItem>: View {
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

private struct GeoKitMapHostModifier<
    Card: GeoKitLiveMapCard & AXCardItem,
    Collection: AXCardCollectionModel<Card>
>: ViewModifier {
    @ObservedObject var coordinator: GeoKitCardMapCoordinator<Card>
    @ObservedObject var collection: Collection
    let layout: CardMediaCollectionLayout
    var mediaContentSize: () -> CGSize
    var skipSnapshotCapture: () -> Bool
    var onAppear: (() -> Void)?
    var embedsLiveHost: Bool

    private var shouldRevealCollection: Bool {
        if skipSnapshotCapture() { return true }
        if !coordinator.mediaStore.hidesStackUntilInitialFocusedStaticReady { return true }
        if coordinator.mediaStore.hasRevealedCardStack { return true }
        return coordinator.mediaStore.isInitialFocusedStaticReady
    }

    func body(content: Content) -> some View {
        Group {
            if embedsLiveHost {
                layeredContent(content)
                    .backgroundPreferenceValue(AXCardMediaSurfaceFramePreferenceKey.self) { entries in
                        GeoKitMapLiveHost(
                            entries: entries,
                            collection: collection,
                            coordinator: coordinator
                        )
                    }
            } else {
                layeredContent(content)
            }
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

    private func layeredContent(_ content: Content) -> some View {
        content
            .opacity(shouldRevealCollection ? 1 : 0)
            .allowsHitTesting(shouldRevealCollection)
            .animation(.easeOut(duration: 0.12), value: shouldRevealCollection)
            .environmentObject(coordinator)
            .environmentObject(coordinator.cameraStore)
            .environmentObject(coordinator.mediaStore)
    }
}

public extension View {
    /// Installs map media plugin coordination and the persistent expanded live-map host.
    func geoKitMapHost<Card: GeoKitLiveMapCard & AXCardItem, Collection: AXCardCollectionModel<Card>>(
        coordinator: GeoKitCardMapCoordinator<Card>,
        collection: Collection,
        layout: CardMediaCollectionLayout = .stack,
        mediaContentSize: @escaping () -> CGSize = { .zero },
        skipSnapshotCapture: @escaping () -> Bool = { false },
        onAppear: (() -> Void)? = nil,
        embedsLiveHost: Bool = true
    ) -> some View {
        modifier(
            GeoKitMapHostModifier(
                coordinator: coordinator,
                collection: collection,
                layout: layout,
                mediaContentSize: mediaContentSize,
                skipSnapshotCapture: skipSnapshotCapture,
                onAppear: onAppear,
                embedsLiveHost: embedsLiveHost
            )
        )
    }

    /// Positions the persistent live map behind this view (e.g. on ``AX.Stack`` before a hoisted ``CardExpanded`` overlay).
    func geoKitMapLiveHostBackground<Card: GeoKitLiveMapCard & AXCardItem, Collection: AXCardCollectionModel<Card>>(
        coordinator: GeoKitCardMapCoordinator<Card>,
        collection: Collection
    ) -> some View {
        backgroundPreferenceValue(AXCardMediaSurfaceFramePreferenceKey.self) { entries in
            GeoKitMapLiveHost(
                entries: entries,
                collection: collection,
                coordinator: coordinator
            )
        }
    }
}
#endif
