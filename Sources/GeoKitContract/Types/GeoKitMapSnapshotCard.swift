#if os(iOS)
import CoreGraphics
import UIKit

/// Card storage surface for GeoKit peek snapshots (Mapbox or Apple). Host apps implement on their card model.
@MainActor
public protocol GeoKitMapSnapshotCard: AnyObject {
    var id: String { get }
    var frozenSnapshot: UIImage? { get set }
    var mapSnapshotSize: CGSize { get set }
    var snapshotPrefetchScheduled: Bool { get set }
    func mapSnapshotRequest(provider: MapProviderId) -> MapContentRequest
}
#endif
