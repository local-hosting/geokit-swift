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
    @State private var pinGeometryRevision = 0
    @State private var renderedPins: [MapPin] = []
    @State private var lastSettledLayoutSize: CGSize = .zero
    @State private var trackedIdentity:  LiveMapRequestIdentity?
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
        let frame = mapCameraFrame(from: cameraState)
        // Synchronous cache — collapse can start before deferred preference → store writes land.
        GeoKitLiveCameraCache.note(frame, for: request.id)
        if reportedCameraFrame?.isApproximatelyEqual(to: frame) != true {
            reportedCameraFrame = frame
        }
    }

    private func mapCameraFrame(from cameraState: CameraState) -> MapCameraFrame {
        MapCameraFrame(
            centerLatitude: cameraState.center.latitude,
            centerLongitude: cameraState.center.longitude,
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: cameraState.pitch
        )
    }

    private func syncRenderedPinsFromRequest() {
        renderedPins = request.pins
    }

    private var pinCoordinateSignature: String {
        renderedPins
            .map { "\($0.id.uuidString):\($0.latitude):\($0.longitude)" }
            .joined(separator: "|")
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

    private func reloadForStyleChange() {
        didApplyInitialCamera = false
        initialCameraSettled = false
        liveDidRender = false
        syncRenderedPinsFromRequest()
    }

    private func retargetForCardChange() {
        syncRenderedPinsFromRequest()
        let frame = MapCameraFrameResolver.resolve(for: request)
        reportedCameraFrame = frame
        if LiveMapRetargetPolicy.keepsLivePaintedOnRetarget(liveAlreadyPainted: liveDidRender) {
            initialCameraSettled = true
        }
    }

    private func handleCardIdentityChange() {
        let next = LiveMapRequestIdentity(request: request)
        let action = LiveMapRetargetPolicy.cardChangeAction(previous: trackedIdentity, next: next)
        switch action {
        case .retargetCameraAndPins:
            retargetForCardChange()
        case .reloadStyle:
            reloadForStyleChange()
        }
        trackedIdentity = next
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
        GeoKitLiveCameraCache.note(frame, for: request.id)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let canMount = MapSurfaceMountPolicy.canMountMap(surfaceReady: mapSurfaceReady, layoutSize: size)
            let showMap = MapSurfaceMountPolicy.shouldShowLiveMap(
                canMount: canMount,
                mapReady: mapReady,
                isTransitioning: isTransitioning,
                liveAlreadyPainted: liveDidRender
            )
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
                                livePinAnnotations(zoom: pinZoom)
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
                            let cameraState = event.cameraState
                            // Stash immediately — collapse may begin before the deferred SwiftUI writes run.
                            GeoKitLiveCameraCache.note(mapCameraFrame(from: cameraState), for: request.id)
                            guard !isTransitioning else { return }
                            // Mapbox can emit camera changes synchronously while SwiftUI is applying the
                            // viewport binding mid view-update; defer the @State / preference writes.
                            DispatchQueue.main.async {
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
                        // Mapbox MapView ignores SwiftUI allowsHitTesting — force UIKit off when collapsed.
                        .geokitPlatformMapUserInteraction(request.mapAcceptsUserInteraction)
                        .geokitIsolatePlatformMapAccessibility()
                    }
                }
                // Mapbox's GL surface paints an opaque base the instant it mounts, compositing *above* the
                // frozen underlay below — so that underlay can't mask the cold load (the host handoff
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
            .onAppear {
                DispatchQueue.main.async { syncRenderedPinsFromRequest() }
                trackedIdentity = LiveMapRequestIdentity(request: request)
            }
            .onChange(of: request.pins) { _, _ in
                DispatchQueue.main.async { syncRenderedPinsFromRequest() }
            }
            .onChange(of: request.livePinGeometryEpoch) { _, _ in
                DispatchQueue.main.async { syncRenderedPinsFromRequest() }
            }
            .onChange(of: pinCoordinateSignature) { _, _ in
                DispatchQueue.main.async { pinGeometryRevision &+= 1 }
            }
            .onChange(of: size) { _, newSize in
                DispatchQueue.main.async {
                    noteLayoutSizeChange(newSize)
                    syncMapReady(for: newSize)
                }
            }
            .onChange(of: mapSurfaceReady) { _, _ in
                DispatchQueue.main.async { syncMapReady(for: size) }
            }
            .onChange(of: request.id) { _, _ in
                handleCardIdentityChange()
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
                DispatchQueue.main.async {
                    syncMapReady(for: size)
                    if MapSurfaceMountPolicy.isValidLayoutSize(size) {
                        lastSettledLayoutSize = size
                    }
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
                    guard !MapSurfaceMountPolicy.retainsWarmMountDuringTransitionGap(
                        isTransitioning: isTransitioning,
                        liveAlreadyPainted: liveDidRender
                    ) else { return }
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
                    // Flush the last live camera before reporting gates close — collapse can flip
                    // transitioning before a deferred onCameraChanged lands in the store.
                    if let cameraState = liveCameraState {
                        reportCameraFrame(cameraState)
                    } else if let cached = GeoKitLiveCameraCache.frame(for: request.id) {
                        GeoKitLiveCameraCache.note(cached, for: request.id)
                        if reportedCameraFrame?.isApproximatelyEqual(to: cached) != true {
                            reportedCameraFrame = cached
                        }
                    }
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


    /// Primary pins use SwiftUI view annotations so live coordinate updates stay visible; secondary pins stay on GPU circles.
    @MapContentBuilder
    private func livePinAnnotations(zoom: CGFloat) -> some MapContent {
        let _ = pinGeometryRevision
        let dot = GeoKitPinDotMetrics.unselected(zoom: zoom)
        ForEvery(renderedPins) { pin in
            if pin.id == selectedPinId {
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
            } else if pin.isPrimary {
                MapViewAnnotation(coordinate: pin.coordinate) {
                    GeoKitPlacePinView(
                        pin: pin,
                        zoom: zoom,
                        tap: GeoKitTap(id: pin.id, coordinate: pin.coordinate),
                        color: GeoKitMapTheme.accent,
                        pinStyle: .primary,
                        onTap: { tapped, _, isCircleTap in onPinTap(tapped, isCircleTap) },
                        onInteractionBegan: onPinInteractionBegan,
                        selected: false,
                        visible: true,
                        allowCallout: false,
                        showText: false
                    )
                }
                .priority(1)
                .allowOverlap(true)
                .allowOverlapWithPuck(true)
                .variableAnchors([ViewAnnotationAnchor.bottom].map { ViewAnnotationAnchorConfig(anchor: $0) })
            } else {
                CircleAnnotation(centerCoordinate: pin.coordinate)
                    .circleColor(StyleColor(UIColor(GeoKitMapTheme.secondary)))
                    .circleRadius(Double(dot.diameter) / 2)
                    .circleStrokeColor(StyleColor(UIColor.white))
                    .circleStrokeWidth(Double(dot.strokeWidth))
                    .onTapGesture {
                        onPinTap(pin, true)
                    }
            }
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
