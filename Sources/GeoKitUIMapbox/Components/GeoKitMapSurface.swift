#if os(iOS) || os(visionOS)

import CoreLocation
import GeoKitContract
import GeoKitUI
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
    @Environment(\.geokitAnimationSpeed) private var animationSpeed

    @State private var mapReady = false
    @State private var reportedCameraFrame: MapCameraFrame?
    @State private var liveDidRender = false
    @State private var didApplyInitialCamera = false
    @State private var pinZoomHold: CGFloat?
    @State private var pinsLayoutSettling = false
    @State private var lastSettledLayoutSize: CGSize = .zero
    /// One-shot: the live surface is anchored at its shared camera. The live map seeds directly at the
    /// resolved `saved ?? declared` camera (an imperative `setCamera` jump — the same frame the snapshot
    /// was captured at), so there is no fly-to to cross and settle is satisfied the moment that camera is
    /// applied. The dark cover then lifts on the first paint, never revealing an uncentered light map.
    @State private var initialCameraSettled = false

    /// Cover may lift only once the live surface has painted and reached its target camera (or mid-transition).
    private var liveSurfaceRevealed: Bool {
        LiveMapRevealPolicy.revealsLiveSurface(
            livePainted: liveDidRender,
            cameraSettledAtTarget: initialCameraSettled,
            isTransitioning: isTransitioning
        )
    }

    private func noteCameraSettledIfNeeded() {
        guard !initialCameraSettled else { return }
        let target = MapCameraFrameResolver.resolve(for: request)
        if MapCameraFrameResolver.isCameraSettledAtTarget(reportedCameraFrame, target: target) {
            initialCameraSettled = true
        }
    }

    /// Persist the live camera as the user moves it — not only at idle. A collapse can flip
    /// `isTransitioning` (and remount the hoisted surface) before the post-pan `onMapIdle` fires; if the
    /// frame is only reported on idle, the panned camera never reaches the shared store and the remount
    /// resolves back to the declared camera. Reporting on every interactive change keeps the store current
    /// so `frame(for:id)` already holds the user's camera before any handoff. The store dedups and debounces.
    private func reportCameraFrame(_ cameraState: CameraState) {
        let frame = MapCameraFrame(
            centerLatitude: cameraState.center.latitude,
            centerLongitude: cameraState.center.longitude,
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: cameraState.pitch
        )
        if reportedCameraFrame?.isApproximatelyEqual(to: frame) != true {
            reportedCameraFrame = frame
        }
    }

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
        // Single shared camera: we jumped the live surface straight to the resolved camera (no fly-to), so
        // it is already at its target. Record that frame and mark settled now — the imperative jump emits no
        // `onCameraChanged`/`onMapIdle`, so waiting on a reported match would strand the cover until the
        // timeout. The cover still holds until the first paint via `liveDidRender`.
        reportedCameraFrame = frame
        initialCameraSettled = true
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
            let showMap = MapSurfaceMountPolicy.shouldShowLiveMap(canMount: canMount, mapReady: mapReady)
            // Reported to the host so it can lift the in-card cover once the surface shows map content — true
            // while the snapshot cover bridges the cold load, even before the live surface paints.
            let showFrozenUnderlay = frozenSnapshot != nil && !liveDidRender && !isTransitioning
            let pinZoom = resolvedPinZoom(isTransitioning: isTransitioning)
            ZStack {
                // Backstop only — the snapshot cover below sits above the live map and spans both the
                // pre-mount and mounted-but-unpainted windows, so this is seen only if neither ever paints.
                GeoKitMapTheme.placeholderBackground
                    .frame(width: size.width, height: size.height)
                if showMap {
                    MapReader { proxy in
                        MapboxMaps.Map(viewport: $viewport) {
                            StyleProjection(name: .mercator)
                            if request.showUserPuck {
                                Puck2D().pulsing(.default)
                            }
                            if !hideLiveMapPins {
                                // Unselected pins draw as a GPU circle layer (CircleAnnotationGroup → a managed
                                // CircleLayer). Moving a pin updates the renderer's GeoJSON source, so the dot
                                // travels on the GPU instead of reflowing a SwiftUI view annotation every frame.
                                unselectedPinCircles(zoom: pinZoom)
                                // The selected pin keeps the SwiftUI callout view annotation for its label + tail.
                                selectedPinAnnotation(zoom: pinZoom)
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
                            let cameraState = event.cameraState
                            let zoom = cameraState.zoom
                            liveCameraState = cameraState
                            zoomLevel = Float(zoom)
                            currentZoom = zoom
                            isPlusEnabled = zoom < 19
                            isMinusEnabled = zoom > 10
                            // The map is the map: persist every interactive move so the shared store is
                            // current before a collapse can preempt the post-pan idle.
                            reportCameraFrame(cameraState)
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
                            // Read the live camera from the proxy: imperative setCamera doesn't emit
                            // onCameraChanged, so liveCameraState can still be nil at the first idle.
                            guard !isTransitioning, let cameraState = liveCameraState ?? proxy.map?.cameraState else { return }
                            reportCameraFrame(cameraState)
                            // The first idle can land at the style's default camera before the fly-to. Only
                            // mark settled once the reported camera reaches the card's pins.
                            noteCameraSettledIfNeeded()
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
                        .geokitIsolatePlatformMapAccessibility()
                    }
                }
                // Mapbox's GL surface paints an opaque base the instant it mounts, compositing *above* the
                // frozen underlay below — so that underlay can't mask the cold load (the carousel-handoff
                // gray flash). Keep the live map underneath and hold this cover *above* it until the surface
                // has painted and settled, then cross-fade. The cover is the frozen snapshot when we have one
                // (seamless continuity from the card image), the dark placeholder otherwise (cold first load).
                Group {
                    if let snapshot = frozenSnapshot {
                        Image(uiImage: snapshot)
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
                        livePainted: liveSurfaceRevealed
                    ) ? 1 : 0
                )
                .allowsHitTesting(false)
                .animation(
                    .easeOut(duration: GeoKitMapCrossFadeConstants.scaledDuration(animationSpeed: animationSpeed)),
                    value: liveSurfaceRevealed
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
            .onChange(of: request.id) { _, _ in
                didApplyInitialCamera = false
                initialCameraSettled = false
            }
            .task(id: request.id) {
                // Never strand the cover: if the camera can't reach the pins (e.g. tiles never load), lift
                // after a bounded window so the surface isn't hidden forever.
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                if !initialCameraSettled {
                    initialCameraSettled = true
                }
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
                initialCameraSettled = false
                pinsLayoutSettling = false
                lastSettledLayoutSize = .zero
            }
            .onChange(of: showMap) { _, isShowing in
                if isShowing {
                    GeoKitMapboxLiveMapRegistry.registerLiveMap()
                } else {
                    liveDidRender = false
                    initialCameraSettled = false
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
                value: (showMap && liveSurfaceRevealed) || showFrozenUnderlay
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


    /// GPU-rendered dots for every pin that is not currently selected.
    @MapContentBuilder
    private func unselectedPinCircles(zoom: CGFloat) -> some MapContent {
        let dot = GeoKitPinDotMetrics.unselected(zoom: zoom)
        CircleAnnotationGroup(request.pins.filter { $0.id != selectedPinId }) { pin in
            let pinColor = pin.isPrimary ? GeoKitMapTheme.accent : GeoKitMapTheme.secondary
            return CircleAnnotation(centerCoordinate: pin.coordinate)
                .circleColor(StyleColor(UIColor(pinColor)))
                .circleRadius(Double(dot.diameter) / 2)
                .circleStrokeColor(StyleColor(UIColor.white))
                .circleStrokeWidth(Double(dot.strokeWidth))
                .onTapGesture {
                    onPinTap(pin, true)
                }
        }
    }

    /// SwiftUI callout view annotation for the selected pin (label + tail can't live on a style layer).
    @MapContentBuilder
    private func selectedPinAnnotation(zoom: CGFloat) -> some MapContent {
        if let selectedPinId, let pin = request.pins.first(where: { $0.id == selectedPinId }) {
            MapViewAnnotation(coordinate: pin.coordinate) {
                GeoKitPlacePinView(
                    pin: pin,
                    zoom: zoom,
                    tap: GeoKitTap(id: pin.id, coordinate: pin.coordinate),
                    color: pin.isPrimary ? GeoKitMapTheme.accent : GeoKitMapTheme.secondary,
                    pinStyle: pin.isPrimary ? .primary : .secondary,
                    onTap: { tapped, _, isCircleTap in onPinTap(tapped, isCircleTap) },
                    onInteractionBegan: onPinInteractionBegan,
                    selected: true,
                    visible: true,
                    allowCallout: true,
                    showText: true
                )
            }
            .priority(1)
            .allowOverlap(true)
            .allowOverlapWithPuck(true)
            .variableAnchors([ViewAnnotationAnchor.bottom].map { ViewAnnotationAnchorConfig(anchor: $0) })
        }
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
