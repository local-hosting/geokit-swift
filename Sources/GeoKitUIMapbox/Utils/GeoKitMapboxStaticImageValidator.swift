#if os(iOS) || os(visionOS)

import GeoKitUI
import UIKit

/// Rejects uniform plates from the Static Images API — real map tiles always vary across the sample grid.
enum GeoKitMapboxStaticImageValidator {
    static func hasVisibleMapContent(_ image: UIImage) -> Bool {
        GeoKitMapSnapshotContentPolicy.acceptsPersistedMapBitmap(image)
    }
}
#endif
