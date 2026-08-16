#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import SwiftUI

/// Aspect-fills a slot with a peek snapshot — always fills the container width-to-height.
struct GeoKitSnapshotImageFill: View {
    let image: GeoKitPlatformImage
    var alignment: Alignment = .center

    var body: some View {
        Image(geoKitImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .clipped()
    }
}
#endif
