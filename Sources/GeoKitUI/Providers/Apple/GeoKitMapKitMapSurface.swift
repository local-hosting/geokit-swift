#if os(iOS)
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
    var frozenSnapshot: UIImage?

    @Environment(\.geokitMapSurfaceReady) private var mapSurfaceReady
    @Environment(\.geokitMapIsTransitioning) private var isTransitioning

    @State private var mapReady = false
    @State private var reportedCameraFrame: MapCameraFrame?

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
        let validSize = MapSurfaceMountPolicy.isValidLayoutSize(size)
        let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
        let showMap = MapSurfaceMountPolicy.shouldShowLiveMap(canMount: canMount, mapReady: mapReady)
        let showFrozen = isTransitioning && frozenSnapshot != nil

        ZStack {
            Color.white
            if showFrozen, let snapshot = frozenSnapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else if showMap {
                liveMap(size: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: size) { _, newSize in
            syncMapReady(for: newSize)
        }
        .onChange(of: mapSurfaceReady) { _, _ in
            syncMapReady(for: size)
        }
        .onAppear {
            syncMapReady(for: size)
        }
        .onDisappear {
            mapReady = false
        }
        .preference(key: GeoKitMapCameraFrameKey.self, value: reportedCameraFrame)
        .preference(key: GeoKitLiveRenderingKey.self, value: showMap && !showFrozen)
        .preference(key: GeoKitMapRenderedKey.self, value: showMap || showFrozen)
    }

    private func liveMap(size: CGSize) -> some View {
        Map(position: $position, interactionModes: request.mapAcceptsUserInteraction ? .all : []) {
            if request.showUserPuck {
                UserAnnotation()
            }
            ForEach(request.pins) { (pin: GeoKitContract.MapPin) in
                pinAnnotation(for: pin)
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
            reportedCameraFrame = GeoKitMapKitCamera.frame(from: camera)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            reportedCameraFrame = GeoKitMapKitCamera.frame(from: context.camera)
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
                color: GeoKitMapTheme.accent,
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
