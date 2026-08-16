#if os(iOS)
import Foundation
import GeoKitUI
import MapboxMaps

public enum GeoKitMapboxViewportSettled {
    /// Observe viewport settle events on a Mapbox map.
    public static func observe(
        map: MapboxMap,
        onSettled: @escaping () -> Void
    ) -> [Cancelable] {
        let coordinator = GeoKitMapViewportSettledCoordinator(onSettled: onSettled)

        return [
            map.onMapIdle.observe { _ in coordinator.handleInteractionEnd() },
            map.onCameraChanged.observe { _ in coordinator.handleMove() },
        ]
    }
}
#endif
