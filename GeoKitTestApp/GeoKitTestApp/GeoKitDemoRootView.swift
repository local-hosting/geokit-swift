import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Single live map that animates between a centered card and full screen.
/// The same map surface is reused across states (one hoisted map), it just resizes.
struct GeoKitDemoRootView: View {
    @State private var isExpanded = false

    private static let collapsedHeight: CGFloat = 460
    private static let collapsedCornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            mapCard
        }
        .overlay(alignment: .topLeading) {
            if isExpanded {
                collapseButton
                    .padding(.leading, 20)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var mapCard: some View {
        map
            .allowsHitTesting(isExpanded)
            .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : Self.collapsedHeight)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: isExpanded ? 0 : Self.collapsedCornerRadius,
                    style: .continuous
                )
            )
            .overlay(alignment: .bottom) {
                if !isExpanded { expandHint }
            }
            .shadow(color: .black.opacity(isExpanded ? 0 : 0.45), radius: 22, y: 12)
            .padding(isExpanded ? 0 : 20)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded { toggle() }
            }
            .ignoresSafeArea(edges: isExpanded ? .all : [])
    }

    private var map: some View {
        GeoKitMapContentWithLifecycle(
            id: "home-map",
            policy: MapStagePolicy(stage: isExpanded ? .expand : .center, isExpanded: isExpanded),
            lifecycle: MapLifecycleState(isStyleReady: true, isSurfaceReady: true),
            isExpanded: isExpanded,
            mapStyleURI: GeoKitDemoConstants.liveMapStyleURI,
            preferredZoom: 12
        )
    }

    private var expandHint: some View {
        Label("Tap to expand", systemImage: "arrow.up.left.and.arrow.down.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 18)
    }

    private var collapseButton: some View {
        Button(action: toggle) {
            Image(systemName: "chevron.down")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityIdentifier("geokit-collapse-button")
    }

    private func toggle() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            isExpanded.toggle()
        }
    }
}
