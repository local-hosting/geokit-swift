#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import CoreLocation
import GeoKitContract
import MapKit
import SwiftUI

struct GeoKitMapKitMapSurface: View {
    let request: MapContentRequest
    @Binding var position: MapCameraPosition
    @Binding var zoomLevel: Float
    let selectedPinId: UUID?
    let onPinTap: (GeoKitContract.MapPin, Bool) -> Void
    let onPinInteractionBegan: () -> Void
    var onPinInteractionEnded: (() -> Void)?
    var frozenSnapshot: GeoKitPlatformImage?

    @Environment(\.geokitMapSurfaceReady) private var mapSurfaceReady
    @Environment(\.geokitMapIsTransitioning) private var isTransitioning
    @Environment(\.geokitAnimationSpeed) private var animationSpeed

    @State private var mapReady = false
    @State private var liveDidRender = false
    @State private var reportedCameraFrame: MapCameraFrame?
    @State private var pinsLayoutSettling = false
    @State private var lastSettledLayoutSize: CGSize = .zero

    private var hideLiveMapPins: Bool {
        MapPinTransitionCoverPolicy.hideLiveMapPins(
            mapIsTransitioning: isTransitioning,
            pinsLayoutSettling: pinsLayoutSettling,
            livePainted: liveDidRender
        )
    }

    private func snapshotCoversLive(mapVisible: Bool) -> Bool {
        MapPinTransitionCoverPolicy.snapshotCoversLive(
            mapIsTransitioning: isTransitioning,
            pinsLayoutSettling: pinsLayoutSettling,
            livePainted: mapVisible && liveDidRender
        )
    }

    private func noteLayoutSizeChange(_ newSize: CGSize) {
        if MapPinLayoutSettlingPolicy.shouldBeginSettling(
            isTransitioning: isTransitioning,
            previousSize: lastSettledLayoutSize,
            newSize: newSize,
            mapReady: mapReady
        ) {
            pinsLayoutSettling = true
        }
    }

    private func markLayoutSettled(_ size: CGSize) {
        if MapSurfaceMountPolicy.isValidLayoutSize(size) {
            lastSettledLayoutSize = size
        }
        pinsLayoutSettling = false
    }

    var body: some View {
        GeometryReader { geo in
            mapBody(size: geo.size)
        }
        .clipped()
    }


    private func syncMapReady(for size: CGSize) {
        let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
        mapReady = canMount
    }

    @ViewBuilder
    private func mapBody(size: CGSize) -> some View {
        let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
        let showMap = MapSurfaceMountPolicy.shouldShowLiveMap(canMount: canMount, mapReady: mapReady)
        // Tile snapshots omit pins — keep them under the live map during card transitions.
        let showFrozenUnderlay = isTransitioning && frozenSnapshot != nil && !liveDidRender

        ZStack {
            GeoKitMapTheme.placeholderBackground
            if showFrozenUnderlay, let snapshot = frozenSnapshot {
                Image(geoKitImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)
            }
            if showMap {
                liveMap(size: size)
            }
            // Mirror the Mapbox surface: keep the live map underneath and hold a cover above it until its
            // first paint so a cold load can't flash the surface's blank base. The cover is the frozen
            // snapshot when we have one (seamless continuity from the card image), the dark placeholder
            // otherwise — the underlay alone can't mask an opaque live base that composites above it.
            Group {
                if let snapshot = frozenSnapshot {
                    Image(geoKitImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    GeoKitMapTheme.placeholderBackground
                        .frame(width: size.width, height: size.height)
                }
            }
            .opacity(
                MapPinTransitionCoverPolicy.coversLiveSurface(
                    showMap: showMap,
                    livePainted: liveDidRender
                ) ? 1 : 0
            )
            .allowsHitTesting(false)
            .animation(
                .easeOut(duration: GeoKitMapCrossFadeConstants.scaledDuration(animationSpeed: animationSpeed)),
                value: liveDidRender
            )
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: size) { _, newSize in
            noteLayoutSizeChange(newSize)
            syncMapReady(for: newSize)
        }
        .onChange(of: mapSurfaceReady) { _, _ in
            syncMapReady(for: size)
        }
        .onAppear {
            syncMapReady(for: size)
            if MapSurfaceMountPolicy.isValidLayoutSize(size) {
                lastSettledLayoutSize = size
            }
        }
        .onDisappear {
            mapReady = false
            liveDidRender = false
            pinsLayoutSettling = false
            lastSettledLayoutSize = .zero
        }
        .onChange(of: showMap) { _, isShowing in
            if !isShowing {
                liveDidRender = false
            }
        }
        .preference(key: GeoKitMapCameraFrameKey.self, value: reportedCameraFrame)
        .preference(key: GeoKitLiveRenderingKey.self, value: showMap && liveDidRender && !hideLiveMapPins)
        .preference(
            key: GeoKitMapRenderedKey.self,
            value: (showMap && liveDidRender) || showFrozenUnderlay
        )
        .preference(key: GeoKitMapSnapshotCoversLiveKey.self, value: showMap && snapshotCoversLive(mapVisible: showMap))
        .onChange(of: isTransitioning) { wasTransitioning, transitioning in
            if transitioning, !wasTransitioning {
                pinsLayoutSettling = false
            }
        }
    }

    private func liveMap(size: CGSize) -> some View {
        Map(position: $position, interactionModes: request.mapAcceptsUserInteraction ? .all : []) {
            if request.showUserPuck {
                UserAnnotation()
            }
            if !hideLiveMapPins {
                ForEach(request.pins) { (pin: GeoKitContract.MapPin) in
                    pinAnnotation(for: pin)
                }
            }
        }
        .mapStyle(GeoKitMapProviderRegistry.apple.mapStyle.mapKitStyle)
        .onMapCameraChange(frequency: .continuous) { context in
            let camera = context.camera
            let zoom = GeoKitMapKitCamera.zoom(
                fromDistance: camera.distance,
                latitude: camera.centerCoordinate.latitude
            )
            zoomLevel = Float(zoom)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            if pinsLayoutSettling {
                markLayoutSettled(size)
            } else if MapSurfaceMountPolicy.isValidLayoutSize(size) {
                lastSettledLayoutSize = size
            }
            if !liveDidRender {
                liveDidRender = true
            }
            let nextFrame = GeoKitMapKitCamera.frame(from: context.camera)
            if reportedCameraFrame?.isApproximatelyEqual(to: nextFrame) != true {
                reportedCameraFrame = nextFrame
            }
        }
        .allowsHitTesting(request.mapAcceptsUserInteraction)
        .geokitIgnoresSafeArea(when: request.mapAcceptsUserInteraction)
        .mapSurfaceTouchShield(
            isActive: request.mapAcceptsUserInteraction,
            onBegan: onPinInteractionBegan,
            onEnded: onPinInteractionEnded
        )
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    @MapContentBuilder
    private func pinAnnotation(for pin: GeoKitContract.MapPin) -> some MapContent {
        let isSelected = selectedPinId == pin.id
        Annotation(pin.pinHeading, coordinate: pin.coordinate, anchor: .bottom) {
            GeoKitPlacePinView(
                pin: pin,
                zoom: CGFloat(zoomLevel),
                tap: GeoKitTap(id: pin.id, coordinate: pin.coordinate),
                color: pin.isPrimary ? GeoKitMapTheme.accent : GeoKitMapTheme.secondary,
                pinStyle: pin.isPrimary ? .primary : .secondary,
                onTap: { tapped, _, isCircleTap in onPinTap(tapped, isCircleTap) },
                onInteractionBegan: onPinInteractionBegan,
                selected: isSelected,
                visible: true,
                allowCallout: true,
                showText: true
            )
        }
    }

}

private extension GeoKitContract.MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension View {
    func mapSurfaceTouchShield(
        isActive: Bool,
        onBegan: @escaping () -> Void,
        onEnded: (() -> Void)?
    ) -> some View {
        modifier(MapKitSurfaceTouchShieldModifier(isActive: isActive, onBegan: onBegan, onEnded: onEnded))
    }
}

private struct MapKitSurfaceTouchShieldModifier: ViewModifier {
    let isActive: Bool
    let onBegan: () -> Void
    let onEnded: (() -> Void)?

    func body(content: Content) -> some View {
        if isActive {
            content.simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onBegan() }
                    .onEnded { _ in onEnded?() }
            )
        } else {
            content
        }
    }
}
#endif
