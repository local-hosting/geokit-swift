#if os(iOS)
import SwiftUI
import UIKit

/// Aspect-fills a slot with a peek snapshot — always fills the container width-to-height.
struct GeoKitSnapshotImageFill: View {
    let image: UIImage
    var alignment: Alignment = .center

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .clipped()
    }
}
#endif
