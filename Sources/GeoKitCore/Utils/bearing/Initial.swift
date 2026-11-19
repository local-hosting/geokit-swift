import Foundation

/// Mirrors `geokit/src/core/src/utils/bearing/initial.ts` (`bearing`, `finalBearing`).

public func bearing(_ point1: LatLon) -> (LatLon) -> Double {
    { point2 in Bearing.initial(from: point1, to: point2) }
}

public func bearing(from point1: LatLon, to point2: LatLon) -> Double {
    Bearing.initial(from: point1, to: point2)
}

public func finalBearing(_ point1: LatLon) -> (LatLon) -> Double {
    { point2 in Bearing.final(from: point1, to: point2) }
}

public func finalBearing(from point1: LatLon, to point2: LatLon) -> Double {
    Bearing.final(from: point1, to: point2)
}