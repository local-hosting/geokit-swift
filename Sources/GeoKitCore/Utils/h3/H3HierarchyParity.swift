import Foundation

#if os(iOS) || os(macOS)

/// Mirrors `geokit/src/h3/src/geometry/hierarchy.ts`.

public func h3ToParent(_ h3Index: String, resolution: Int) throws -> String {
    try H3.parent(of: h3Index, resolution: resolution)
}

public func h3ToChildren(_ h3Index: String, resolution: Int) throws -> [String] {
    try H3.children(of: h3Index, resolution: resolution)
}

public func gridDisk(_ h3Index: String, k: Int = 1) throws -> [String] {
    try H3.neighbors(of: h3Index, k: k)
}

#endif