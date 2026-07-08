import GeoKitContract
import GeoKitUI
import SwiftUI

/// Standalone GeoKit demo — hoisted map with pins, card paging, provider switching, and expand/collapse.
struct GeoKitDemoRootView: View {
    @State private var selectedPage = 0
    @State private var isExpanded = false
    @State private var mapProvider: MapProviderId = .mapbox
    @State private var centerMediaReady = false
    @State private var selectedPinId: UUID? = GeoKitDemoPlaces.all.first?.defaultSelectedPinId

    private static let collapsedHeight: CGFloat = 460
    private static let collapsedCornerRadius: CGFloat = 28

    private var place: GeoKitDemoPlace {
        GeoKitDemoPlaces.all[selectedPage]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer(minLength: 0)
                mapCard
                if !GeoKitDemoLaunchArguments.isUITestMode {
                    pinSelector
                }
                footerBadge
                pageDots
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            if !isExpanded {
                providerPicker
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            if GeoKitDemoLaunchArguments.isUITestMode, !isExpanded {
                uiTestCitySelector
                    .padding(.top, 56)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .accessibilityIdentifier("geokit-test-app.root")
        .overlay { mediaReadyProbe }
        .overlay { collapsedProbe }
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
                if !isExpanded { toggleExpanded() }
            }
            .ignoresSafeArea(edges: isExpanded ? .all : [])
            .accessibilityIdentifier("geokit-test-app.map-card")
    }

    private var map: some View {
        GeoKitMapContentWithLifecycle(
            id: place.id,
            policy: MapStagePolicy(stage: isExpanded ? .expand : .center, isExpanded: isExpanded),
            lifecycle: MapLifecycleState(isStyleReady: true, isSurfaceReady: true),
            isExpanded: isExpanded,
            title: place.title,
            mapStyleURI: GeoKitDemoConstants.liveMapStyleURI,
            preferredZoom: place.preferredZoom,
            pins: place.pins,
            showUserPuck: false,
            mapProviderId: mapProvider,
            selectedPinId: selectedPinId
        )
        .onPreferenceChange(GeoKitMapRenderedKey.self) { rendered in
            centerMediaReady = rendered
        }
        .onPreferenceChange(GeoKitSelectedPinIdKey.self) { pinId in
            if let pinId { selectedPinId = pinId }
        }
    }


    @ViewBuilder
    private var pinSelector: some View {
        if place.extraPins.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                ForEach(place.pins, id: \.id) { pin in
                    Button(pin.pinHeading) { selectedPinId = pin.id }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedPinId == pin.id ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .accessibilityLabel(pin.pinHeading)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier("geokit-test-app.pin-\(pin.id.uuidString.lowercased())")
                }
            }
        }
    }

    private var footerBadge: some View {
        VStack(spacing: 4) {
            Text(place.badge)
            if let pin = place.pins.first(where: { $0.id == selectedPinId }) {
                Text(pin.pinHeading)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityIdentifier("geokit-test-app.selected-pin-heading")
                    .accessibilityLabel(pin.pinHeading)
            }
        }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("geokit-test-app.footer-badge")
    }

    private var expandHint: some View {
        Label("Tap to expand", systemImage: "arrow.up.left.and.arrow.down.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 56)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Tap to expand")
            .accessibilityIdentifier("geokit-test-app.expand-map")
    }

    private var collapseButton: some View {
        Button(action: toggleExpanded) {
            Image(systemName: "chevron.down")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityIdentifier("geokit-collapse-button")
    }

    private var providerPicker: some View {
        Picker("Map Provider", selection: $mapProvider) {
            Text("Mapbox").tag(MapProviderId.mapbox)
            Text("Apple").tag(MapProviderId.apple)
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
        .accessibilityIdentifier("geokit-test-app.map-provider-picker")
        .onChange(of: selectedPage) { _, _ in
            selectedPinId = place.defaultSelectedPinId
            centerMediaReady = false
        }
        .onChange(of: mapProvider) { _, provider in
            GeoKitMapProviderRegistry.configure(provider: provider)
            GeoKitMapBootstrap.prepare(provider: provider)
            centerMediaReady = false
        }
    }

    private var pageDots: some View {
        HStack(spacing: 0) {
            ForEach(Array(GeoKitDemoPlaces.all.enumerated()), id: \.offset) { index, place in
                Button {
                    guard !isExpanded else { return }
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        selectedPage = index
                    }
                } label: {
                    Circle()
                        .fill(index == selectedPage ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 10, height: 10)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(place.badge)")
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("geokit-test-app.page-\(index)")
            }
        }
    }

    @ViewBuilder
    private var mediaReadyProbe: some View {
        if centerMediaReady {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("geokit-test-app.center-media-ready")
        }
    }


    @ViewBuilder
    private var collapsedProbe: some View {
        if !isExpanded {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("geokit-test-app.collapsed-map")
        }
    }

    private var uiTestCitySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(GeoKitDemoPlaces.all.enumerated()), id: \.offset) { index, place in
                    Button(place.badge) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            selectedPage = index
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(index == selectedPage ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("geokit-test-app.select-\(place.id)")
                }
                if !place.extraPins.isEmpty {
                    ForEach(place.pins, id: \.id) { pin in
                        Button(pin.pinHeading) { selectedPinId = pin.id }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedPinId == pin.id ? Color.white.opacity(0.35) : Color.white.opacity(0.12))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .accessibilityLabel(pin.pinHeading)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("geokit-test-app.pin-\(pin.id.uuidString.lowercased())")
                    }
                }
            }
        }
    }

    private func toggleExpanded() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            isExpanded.toggle()
        }
    }
}
