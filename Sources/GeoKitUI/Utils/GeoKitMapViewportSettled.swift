import Foundation

public final class GeoKitMapViewportSettledCoordinator {
    private var isDragging = false
    private let onSettled: () -> Void

    public init(onSettled: @escaping () -> Void) {
        self.onSettled = onSettled
    }

    public func handleDragStart() {
        isDragging = true
    }

    public func handleDragEnd() {
        isDragging = false
        handleInteractionEnd()
    }

    public func handleMove() {}

    public func handleInteractionEnd() {
        guard !isDragging else { return }
        onSettled()
    }
}
