import Foundation

/// Node export names for `geokit/src/core/src/utils/geojson/validation.ts`.

public func validateGeoJSON(_ feature: GeoJSONFeature) -> GeoJSONValidationResult {
    GeoJSONValidation.validate(feature)
}

public func validateGeoJSON(_ collection: GeoJSONFeatureCollection) -> GeoJSONValidationResult {
    GeoJSONValidation.validate(collection)
}

public func validateGeoJSON(_ geometry: GeoJSONGeometry) -> GeoJSONValidationResult {
    GeoJSONValidation.validate(geometry)
}