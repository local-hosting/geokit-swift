import GeoKitContract
import XCTest

final class LiveMapRetargetPolicyTests: XCTestCase {
    private let styleA = "mapbox://styles/a"
    private let styleB = "mapbox://styles/b"

    func testSameStyleFocusFlipRetargets() {
        let previous = LiveMapRequestIdentity(id: "card-a", mapStyleURI: styleA, mapProviderId: .mapbox)
        let next = LiveMapRequestIdentity(id: "card-b", mapStyleURI: styleA, mapProviderId: .mapbox)
        XCTAssertEqual(
            LiveMapRetargetPolicy.cardChangeAction(previous: previous, next: next),
            .retargetCameraAndPins
        )
    }

    func testStyleChangeReloads() {
        let previous = LiveMapRequestIdentity(id: "card-a", mapStyleURI: styleA, mapProviderId: .mapbox)
        let next = LiveMapRequestIdentity(id: "card-b", mapStyleURI: styleB, mapProviderId: .mapbox)
        XCTAssertEqual(
            LiveMapRetargetPolicy.cardChangeAction(previous: previous, next: next),
            .reloadStyle
        )
    }

    func testProviderChangeReloads() {
        let previous = LiveMapRequestIdentity(id: "card-a", mapStyleURI: styleA, mapProviderId: .mapbox)
        let next = LiveMapRequestIdentity(id: "card-b", mapStyleURI: styleA, mapProviderId: .apple)
        XCTAssertEqual(
            LiveMapRetargetPolicy.cardChangeAction(previous: previous, next: next),
            .reloadStyle
        )
    }

    func testNilPreviousRetargetsForColdPath() {
        let next = LiveMapRequestIdentity(id: "card-a", mapStyleURI: styleA, mapProviderId: .mapbox)
        XCTAssertEqual(
            LiveMapRetargetPolicy.cardChangeAction(previous: nil, next: next),
            .retargetCameraAndPins
        )
    }

    func testKeepsLivePaintedOnRetargetWhenWarm() {
        XCTAssertTrue(LiveMapRetargetPolicy.keepsLivePaintedOnRetarget(liveAlreadyPainted: true))
        XCTAssertFalse(LiveMapRetargetPolicy.keepsLivePaintedOnRetarget(liveAlreadyPainted: false))
    }

    func testSessionGlobalSurfaceIdentityIsNotCardScoped() {
        XCTAssertEqual(
            LiveMapRetargetPolicy.sessionGlobalSurfaceIdentity,
            "geokit.session-global-live-map"
        )
        XCTAssertFalse(LiveMapRetargetPolicy.sessionGlobalSurfaceIdentity.contains("card"))
    }
}
