#if DEBUG
import AccordDesignSystem
import Foundation

/// Launch with `-CaptureExpandFrames` to auto-navigate to Chicago, open a pin, and expand slowly.
/// Pair with `scripts/capture-expand-frames.sh` and `AX.Animation.speed = 0.1` in app init.
enum GeoKitDemoCaptureHarness {
    static let launchArgument = "-CaptureExpandFrames"
    static let chicagoPageIndex = 3

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    @MainActor
    static func scheduleExpandCapture(deck: GeoKitDemoDeck) {
        guard isActive else { return }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            deck.rotateStackToPage(chicagoPageIndex)
            try? await Task.sleep(for: .seconds(2.0))
            guard let center = deck.cards.first else { return }
            center.selectedPinId = center.pins.first?.id
            try? await Task.sleep(for: .milliseconds(400))
            deck.expandActiveCard()
        }
    }
}
#endif
