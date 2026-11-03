import XCTest
@testable import NavigationCore

final class NavigationTests: XCTestCase {
    func testBothDirectionsAndReversal() {
        for reversed in [false, true] {
            for button: Int64 in [3, 4] {
                var router = NavigationRouter()
                XCTAssertEqual(router.handle(button: button, phase: .down, finderActive: true, enabled: true, reversed: reversed),
                               (button == 3) != reversed ? .back : .forward)
                XCTAssertEqual(router.handle(button: button, phase: .up, finderActive: true, enabled: true, reversed: reversed), .swallow)
            }
        }
    }

    func testOtherAppsButtonsAndDisabledModePassThrough() {
        for button: Int64 in [0, 1, 2, 3, 4, 5] {
            for finder in [false, true] {
                for enabled in [false, true] where !finder || !enabled || ![3, 4].contains(button) {
                    var router = NavigationRouter()
                    for phase: MousePhase in [.down, .drag, .up] {
                        XCTAssertEqual(router.handle(button: button, phase: phase, finderActive: finder, enabled: enabled, reversed: false), .pass)
                    }
                }
            }
        }
    }

    func testCapturedClickStaysPairedAcrossFocusAndSettingsChanges() {
        var router = NavigationRouter()
        XCTAssertEqual(router.handle(button: 3, phase: .down, finderActive: true, enabled: true, reversed: false), .back)
        XCTAssertEqual(router.handle(button: 3, phase: .down, finderActive: true, enabled: true, reversed: false), .swallow)
        XCTAssertEqual(router.handle(button: 3, phase: .drag, finderActive: false, enabled: false, reversed: true), .swallow)
        XCTAssertEqual(router.handle(button: 3, phase: .up, finderActive: false, enabled: false, reversed: true), .swallow)
        XCTAssertEqual(router.handle(button: 3, phase: .up, finderActive: true, enabled: true, reversed: false), .pass)
    }

    func testUncapturedPressIsNotSwallowedAfterSwitchingToFinder() {
        var router = NavigationRouter()
        XCTAssertEqual(router.handle(button: 4, phase: .down, finderActive: false, enabled: true, reversed: false), .pass)
        XCTAssertEqual(router.handle(button: 4, phase: .up, finderActive: true, enabled: true, reversed: false), .pass)
    }
}
