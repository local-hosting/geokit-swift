import AccordDesignSystem
import GeoKit
import GeoKitContract
import GeoKitUI
import GeoKitUIAccord
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GeoKitDemoRootView: View {
    @StateObject private var collection = GeoKitDemoCardCollection()
    @StateObject private var coordinator: GeoKitCardMapCoordinator<GeoKitDemoCard>
    @Namespace private var cardNamespace

    init() {
        let coordinator = GeoKitCardMapCoordinator<GeoKitDemoCard>()
        coordinator.onProviderChanged = { provider in
            GeoKitMapProviderRegistry.configure(provider: provider)
            GeoKitMapBootstrap.prepare(provider: provider)
        }
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    private var showsMapProviderPicker: Bool {
        !collection.isExpanded
    }

    private var centerCard: GeoKitDemoCard? {
        guard collection.cards.indices.contains(collection.currentIndex) else { return nil }
        return collection.cards[collection.currentIndex]
    }

    private var isCenterMediaReady: Bool {
        collection.isFocusedMediaReady(layout: .stack)
            || coordinator.isCenterMediaReady(centerCard: centerCard)
    }

    private var isSessionExpanded: Bool {
        collection.isExpanded || collection.isCollapsing
    }

    var body: some View {
        AXBackdropShell {
            ZStack {
                GeoKitDemoBackdropActivationView()
                cardStackRegion
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .axGlassPlacement(.overScene)
        }
        .environment(\.geokitAnimationSpeed, AX.Animation.speed)
        .accessibilityIdentifier("geokit-test-app.root")
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 12, height: 12)
                .accessibilityElement()
                .accessibilityIdentifier(
                    isCenterMediaReady
                        ? "geokit-test-app.center-media-ready"
                        : "geokit-test-app.center-media-pending"
                )
                .allowsHitTesting(false)
        }
    }

    private var cardStackRegion: some View {
        cardStackWithHoistedOverlay
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("geokit-test-app.stack")
            .overlay(alignment: .bottom) {
                if collection.cards.count > 1 {
                    Color.clear
                        .frame(height: 28)
                        .accessibilityIdentifier("geokit-test-app.stack-paging")
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                if showsMapProviderPicker {
                    mapProviderHeader
                }
            }
    }

    /// Stack fan + hoisted ``CardExpanded``; expanded map lives in-card so it tracks the spring frame.
    private var cardStackWithHoistedOverlay: some View {
        AX.Stack(
            collection: collection,
            cardNamespace: cardNamespace,
            showExpandedOverlay: false,
            stackPadding: AX.StackConstants.defaultPadding,
            isInteractionBlocked: { _ in collection.isExpanded },
            paging: stackPaging
        ) { card, _ in
            GeoKitCardMap(
                card: card,
                loadingAccessibilityIdentifier: "geokit-test-app.card-loading",
                fanLoadingAccessibilityIdentifier: "geokit-test-app.card-loading-fan",
                cardAccessibilityIdentifierPrefix: "geokit-test-app.card"
            )
        } headerContent: { card in
            AXBadge(title: card.title, subtitle: card.subtitle, placement: .cardFooter)
                .accessibilityIdentifier("geokit-test-app.card-badge-\(card.id)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            expandedOverlays
                .zIndex(AX.Constants.ZIndex.overlay)
        }
        .geoKitMapHost(
            coordinator: coordinator,
            collection: collection,
            layout: .stack,
            mediaContentSize: { coordinator.collapsedMapContentSize },
            skipSnapshotCapture: {
                #if DEBUG
                GeoKitDemoLaunchArguments.isUITestMode
                #else
                false
                #endif
            },
            onAppear: {
                #if DEBUG
                if !GeoKitDemoLaunchArguments.isUITestMode {
                    GeoKitDemoCaptureHarness.scheduleExpandCapture(collection: collection)
                }
                #endif
            },
            embedsLiveHost: false
        )
    }

    @ViewBuilder
    private var expandedOverlays: some View {
        if isSessionExpanded {
            CardExpanded(
                model: collection,
                cardNamespace: cardNamespace,
                cardConfig: AXCardConfig(
                    badgeWidthFraction: nil,
                    showsGradientOverlay: true
                ),
                isInteractionBlocked: { _ in true },
                cardContent: { card, _ in
                    GeoKitCardMap(
                        card: card,
                        loadingAccessibilityIdentifier: "geokit-test-app.card-loading",
                        fanLoadingAccessibilityIdentifier: "geokit-test-app.card-loading-fan",
                        cardAccessibilityIdentifierPrefix: "geokit-test-app.card"
                    )
                },
                headerContent: { card in
                    AXBadge(title: card.title, subtitle: card.subtitle, placement: .cardFooter)
                        .accessibilityIdentifier("geokit-test-app.card-badge-\(card.id)")
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .accessibilityIdentifier("geokit-test-app.expanded-overlay")
        }
    }

    private var stackPaging: AXStackPaging? {
        guard collection.cards.count > 1 else { return nil }
        return AXStackPaging(
            pageCount: collection.cards.count,
            currentIndex: collection.stackPageIndex,
            dotColor: AX.Colors.whiteSmoke,
            canSelectPage: { _ in !collection.isTransitioning },
            onPageSelected: { index in
                if collection.isExpanded {
                    collection.switchStackPageWhileExpanded(index)
                } else {
                    collection.rotateStackToPage(index)
                }
            }
        )
    }

    private var mapProviderHeader: some View {
        AX.SegmentedControl(
            selection: $coordinator.provider,
            options: MapProviderId.allCases,
            title: { provider in
                switch provider {
                case .mapbox: "Mapbox"
                case .apple: "MapKit"
                }
            },
            horizontalPadding: 0
        )
        .frame(width: 220)
        .frame(maxWidth: .infinity)
        .padding(.top, AX.Layout.spacingS)
        .padding(.bottom, AX.Layout.spacingL)
        .accessibilityIdentifier("geokit-test-app.map-provider-picker")
    }
}

private struct GeoKitDemoBackdropActivationView: View {
    @EnvironmentObject private var backdrop: AXBackdropController

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onAppear { backdrop.showActive() }
    }
}
