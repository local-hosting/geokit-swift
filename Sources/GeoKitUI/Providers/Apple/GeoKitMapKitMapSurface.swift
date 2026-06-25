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

    var body: some View {
        GeometryReader { geo in
            mapBody(size: geo.size)
        }
        .clipped()
        .preference(key: GeoKitLiveRenderingKey.self, value: true)
    }

    @ViewBuilder
    private func mapBody(size: CGSize) -> some View {
        let validSize = Self.isValidMapLayoutSize(size)
        let canMount = validSize && mapSurfaceReady
        let showMap = mapReady && canMount
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
        .onChange(of: canMount) { _, shouldMount in
            if shouldMount {
                guard !mapReady else { return }
                DispatchQueue.main.async { mapReady = true }
            } else {
                mapReady = false
            }
        }
        .onAppear {
            guard canMount else { return }
            DispatchQueue.main.async { mapReady = true }
        }
    }

    private func liveMap(size: CGSize) -> some View {
        Map(position: $position, interactionModes: request.isExpanded ? .all : []) {
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
            DispatchQueue.main.async {
                zoomLevel = Float(zoom)
            }
        }
        .allowsHitTesting(request.isExpanded)
        .geokitIgnoresSafeArea(when: request.isExpanded)
        .mapSurfaceTouchShield(
            isActive: request.isExpanded,
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

    private static func isValidMapLayoutSize(_ size: CGSize) -> Bool {
        size.width >= GeoKitMapLayout.minMapSize && size.height >= GeoKitMapLayout.minMapSize
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
