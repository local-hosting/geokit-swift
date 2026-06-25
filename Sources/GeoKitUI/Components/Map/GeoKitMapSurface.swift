import CoreLocation
import GeoKitContract
import MapboxMaps
import SwiftUI
import UIKit

struct GeoKitMapSurface: View {
    let request: MapContentRequest
    @Binding var viewport: Viewport
    @Binding var zoomLevel: Float
    @Binding var currentZoom: CGFloat
    @Binding var isPlusEnabled: Bool
    @Binding var isMinusEnabled: Bool
    @Binding var liveCameraState: CameraState?
    let selectedPinId: UUID?
    let onPinTap: (MapPin, Bool) -> Void
    let onPinInteractionBegan: () -> Void
    var onPinInteractionEnded: (() -> Void)?
    var frozenSnapshot: UIImage?

    @Environment(\.geokitMapSurfaceReady) private var mapSurfaceReady
    @Environment(\.geokitMapIsTransitioning) private var isTransitioning

    @State private var mapReady = false

    var body: some View {
        GeometryReader { geo in
            let validSize = Self.isValidMapLayoutSize(geo.size)
            let canMount = validSize && mapSurfaceReady
            let showMap = mapReady && canMount
            let showFrozen = isTransitioning && frozenSnapshot != nil
            ZStack {
                Color.white
                if showFrozen, let snapshot = frozenSnapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if showMap {
                    MapboxMaps.Map(viewport: $viewport) {
                        StyleProjection(name: .mercator)
                        if request.showUserPuck {
                            Puck2D().pulsing(.default)
                        }
                        ForEvery(request.pins) { pin in
                            let isSelected = selectedPinId == pin.id
                            MapViewAnnotation(coordinate: pin.coordinate) {
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
                            .priority(isSelected ? 1 : 0)
                            .allowOverlap(true)
                            .allowOverlapWithPuck(true)
                            .variableAnchors([ViewAnnotationAnchor.bottom].map { ViewAnnotationAnchorConfig(anchor: $0) })
                        }
                    }
                    .mapStyle(MapStyle(uri: StyleURI(rawValue: request.mapStyleURI)!))
                    .onCameraChanged { event in
                        let zoom = event.cameraState.zoom
                        let cameraState = event.cameraState
                        DispatchQueue.main.async {
                            liveCameraState = cameraState
                            zoomLevel = Float(zoom)
                            currentZoom = zoom
                            isPlusEnabled = zoom < 19
                            isMinusEnabled = zoom > 10
                        }
                    }
                    .ornamentOptions(ornamentOptions)
                    .gestureOptions(gestureOptions)
                    .allowsHitTesting(request.isExpanded)
                    .geokitIgnoresSafeArea(when: request.isExpanded)
                    .mapSurfaceTouchShield(
                        isActive: request.isExpanded,
                        onBegan: onPinInteractionBegan,
                        onEnded: onPinInteractionEnded
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
        .clipped()
        .preference(key: GeoKitLiveRenderingKey.self, value: true)
    }

    private static func isValidMapLayoutSize(_ size: CGSize) -> Bool {
        size.width >= GeoKitMapLayout.minMapSize && size.height >= GeoKitMapLayout.minMapSize
    }

    private var ornamentOptions: OrnamentOptions {
        GeoKitMapTokens.liveOrnamentOptions(interactiveGestures: request.isExpanded)
    }

    private var gestureOptions: GestureOptions {
        GestureOptions(
            panEnabled: request.isExpanded,
            pinchEnabled: request.isExpanded,
            rotateEnabled: request.isExpanded,
            pinchPanEnabled: request.isExpanded,
            pitchEnabled: request.isExpanded,
            doubleTapToZoomInEnabled: request.isExpanded,
            doubleTouchToZoomOutEnabled: request.isExpanded,
            quickZoomEnabled: false
        )
    }
}

private extension MapPin {
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
        modifier(MapSurfaceTouchShieldModifier(isActive: isActive, onBegan: onBegan, onEnded: onEnded))
    }
}

private struct MapSurfaceTouchShieldModifier: ViewModifier {
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
