import XCTest
@testable import AppStateKit

final class AppStateKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AppStateKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
