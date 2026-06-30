#if os(iOS) || os(visionOS)

import CoreLocation
import GeoKitContract
import GeoKitUI
import MapboxMaps
import SwiftUI
import UIKit

/// TEMP DEBUG: overlay frozen snapshot and live GL map at 50% so misalignment is visible.
enum GeoKitMapSurfaceDebug {
    /// Dim + tint + force the frozen underlay so both layers composite (muddy — diagnosis only).
    static let overlayLayers = false
    /// Lightweight on-map readout of pin count + render state (clean — no dimming).
    static let showReadout = false
}

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
    @Environment(\.geokitAnimationSpeed) private var animationSpeed

    @State private var mapReady = false
    @State private var reportedCameraFrame: MapCameraFrame?
    @State private var liveDidRender = false
    @State private var didApplyInitialCamera = false
    @State private var pinZoomHold: CGFloat?
    @State private var pinsLayoutSettling = false
    @State private var lastSettledLayoutSize: CGSize = .zero

    private var hideLiveMapPins: Bool {
        MapPinTransitionCoverPolicy.hideLiveMapPins(
            mapIsTransitioning: isTransitioning,
            pinsLayoutSettling: pinsLayoutSettling,
            livePainted: liveDidRender
        )
    }

    private var snapshotCoversLive: Bool {
        MapPinTransitionCoverPolicy.snapshotCoversLive(
            mapIsTransitioning: isTransitioning,
            pinsLayoutSettling: pinsLayoutSettling,
            livePainted: liveDidRender
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

    private func resolvedPinZoom(isTransitioning: Bool) -> CGFloat {
        if let pinZoomHold { return pinZoomHold }
        if isTransitioning {
            return currentZoom > 0 ? currentZoom : CGFloat(zoomLevel)
        }
        return CGFloat(zoomLevel)
    }
    private func syncMapReady(for size: CGSize) {
        let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
        mapReady = canMount
    }

    /// One-shot assert after style/map load — the Mapbox style default camera can win before the viewport binding applies.
    private func applyInitialCameraIfNeeded(on map: MapboxMap) {
        guard !didApplyInitialCamera else { return }
        let frame = MapCameraFrameResolver.resolve(for: request)
        map.setCamera(to: CameraOptions(
            center: CLLocationCoordinate2D(latitude: frame.centerLatitude, longitude: frame.centerLongitude),
            zoom: frame.zoom,
            bearing: frame.bearing,
            pitch: frame.pitch
        ))
        didApplyInitialCamera = true
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
            let showMap = MapSurfaceMountPolicy.shouldShowLiveMap(canMount: canMount, mapReady: mapReady)
            // Tile snapshots omit pins — draw them under the live map so annotations stay visible.
            let showFrozenUnderlay = frozenSnapshot != nil && (GeoKitMapSurfaceDebug.overlayLayers || (!liveDidRender && !isTransitioning))
            let pinZoom = resolvedPinZoom(isTransitioning: isTransitioning)
            ZStack {
                GeoKitMapTheme.placeholderBackground
                if let snapshot = frozenSnapshot, showFrozenUnderlay {
                    Image(uiImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .overlay(GeoKitMapSurfaceDebug.overlayLayers ? Color.red.opacity(0.18) : Color.clear)
                        .opacity(GeoKitMapSurfaceDebug.overlayLayers ? 0.5 : 1)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                if showMap {
                    MapReader { proxy in
                        MapboxMaps.Map(viewport: $viewport) {
                            StyleProjection(name: .mercator)
                            if request.showUserPuck {
                                Puck2D().pulsing(.default)
                            }
                            if !hideLiveMapPins {
                                ForEvery(request.pins) { pin in
                                    let isSelected = selectedPinId == pin.id
                                    MapViewAnnotation(coordinate: pin.coordinate) {
                                        GeoKitPlacePinView(
                                            pin: pin,
                                            zoom: pinZoom,
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
                                    .priority(isSelected ? 1 : 0)
                                    .allowOverlap(true)
                                    .allowOverlapWithPuck(true)
                                    .variableAnchors([ViewAnnotationAnchor.bottom].map { ViewAnnotationAnchorConfig(anchor: $0) })
                                }
                            }
                        }
                        .mapStyle(GeoKitMapboxMapStyle.liveMapStyle(styleURI: request.mapStyleURI))
                        .onStyleLoaded { _ in
                            guard let map = proxy.map else { return }
                            GeoKitMapboxStyleImportConfigurator.applyTransitLabels(on: map)
                            applyInitialCameraIfNeeded(on: map)
                        }
                        .onMapLoaded { _ in
                            guard let map = proxy.map else { return }
                            GeoKitMapboxStyleImportConfigurator.applyTransitLabels(on: map)
                            applyInitialCameraIfNeeded(on: map)
                        }
                        .onCameraChanged { event in
                            guard !isTransitioning else { return }
                            let zoom = event.cameraState.zoom
                            let cameraState = event.cameraState
                            liveCameraState = cameraState
                            zoomLevel = Float(zoom)
                            currentZoom = zoom
                            isPlusEnabled = zoom < 19
                            isMinusEnabled = zoom > 10
                        }
                        .onMapIdle { _ in
                            if let map = proxy.map {
                                GeoKitMapboxStyleImportConfigurator.applyTransitLabels(on: map)
                            }
                            if pinsLayoutSettling {
                                markLayoutSettled(size)
                            } else if !isTransitioning, MapSurfaceMountPolicy.isValidLayoutSize(size) {
                                lastSettledLayoutSize = size
                            }
                            if !liveDidRender {
                                liveDidRender = true
                            }
                            guard !isTransitioning, let cameraState = liveCameraState else { return }
                            let nextFrame = MapCameraFrame(
                                centerLatitude: cameraState.center.latitude,
                                centerLongitude: cameraState.center.longitude,
                                zoom: cameraState.zoom,
                                bearing: cameraState.bearing,
                                pitch: cameraState.pitch
                            )
                            if reportedCameraFrame?.isApproximatelyEqual(to: nextFrame) != true {
                                reportedCameraFrame = nextFrame
                            }
                        }
                        .ornamentOptions(ornamentOptions)
                        .gestureOptions(gestureOptions)
                        .allowsHitTesting(request.mapAcceptsUserInteraction)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .geokitIgnoresSafeArea(when: request.mapAcceptsUserInteraction)
                        .mapSurfaceTouchShield(
                            isActive: request.mapAcceptsUserInteraction,
                            onBegan: onPinInteractionBegan,
                            onEnded: onPinInteractionEnded
                        )
                        .overlay(GeoKitMapSurfaceDebug.overlayLayers ? Color.green.opacity(0.18) : Color.clear)
                        .opacity(GeoKitMapSurfaceDebug.overlayLayers ? 0.5 : 1)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .top) {
                if GeoKitMapSurfaceDebug.showReadout {
                    Text("pins:\(request.pins.count) show:\(showMap ? 1 : 0) live:\(liveDidRender ? 1 : 0) z:\(String(format: "%.1f", Double(zoomLevel)))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: size) { _, newSize in
                noteLayoutSizeChange(newSize)
                syncMapReady(for: newSize)
            }
            .onChange(of: mapSurfaceReady) { _, _ in
                syncMapReady(for: size)
            }
            .onChange(of: request.id) { _, _ in
                didApplyInitialCamera = false
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
                didApplyInitialCamera = false
                pinsLayoutSettling = false
                lastSettledLayoutSize = .zero
            }
            .onChange(of: showMap) { _, isShowing in
                if isShowing {
                    GeoKitMapboxLiveMapRegistry.registerLiveMap()
                } else {
                    liveDidRender = false
                    GeoKitMapboxLiveMapRegistry.unregisterLiveMap()
                }
            }
            .onDisappear {
                if showMap {
                    GeoKitMapboxLiveMapRegistry.unregisterLiveMap()
                }
            }
            .preference(key: GeoKitMapCameraFrameKey.self, value: reportedCameraFrame)
            .preference(key: GeoKitLiveRenderingKey.self, value: showMap && liveDidRender && !hideLiveMapPins)
            .preference(
                key: GeoKitMapRenderedKey.self,
                value: (showMap && liveDidRender) || showFrozenUnderlay
            )
            .preference(key: GeoKitMapSnapshotCoversLiveKey.self, value: showMap && snapshotCoversLive)
            .onChange(of: isTransitioning) { wasTransitioning, transitioning in
                if transitioning, !wasTransitioning {
                    pinZoomHold = currentZoom > 0 ? currentZoom : CGFloat(zoomLevel)
                    pinsLayoutSettling = false
                }
                if wasTransitioning, !transitioning {
                    let heldZoom = pinZoomHold
                    DispatchQueue.main.asyncAfter(deadline: .now() + GeoKitMapCrossFadeConstants.scaledDuration(animationSpeed: animationSpeed)) {
                        if pinZoomHold == heldZoom {
                            pinZoomHold = nil
                        }
                    }
                }
            }
        }
        .clipped()
    }


    private var ornamentOptions: OrnamentOptions {
        GeoKitMapTokens.liveOrnamentOptions(interactiveGestures: request.mapAcceptsUserInteraction)
    }

    private var gestureOptions: GestureOptions {
        GestureOptions(
            panEnabled: request.mapAcceptsUserInteraction,
            pinchEnabled: request.mapAcceptsUserInteraction,
            rotateEnabled: request.mapAcceptsUserInteraction,
            pinchPanEnabled: request.mapAcceptsUserInteraction,
            pitchEnabled: request.mapAcceptsUserInteraction,
            doubleTapToZoomInEnabled: request.mapAcceptsUserInteraction,
            doubleTouchToZoomOutEnabled: request.mapAcceptsUserInteraction,
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
#endif
