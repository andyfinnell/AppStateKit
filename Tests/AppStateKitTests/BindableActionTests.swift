import Foundation
import XCTest
@testable import AppStateKit

final class BindableActionTests: XCTestCase {
    @BindableAction
    enum TestEnum {
        case one(String, Int)
        case two(Float)
    }
    
    func testExtract() {
        let subject = TestEnum.one("hello", 42)
        let actualValue1 = TestEnum.one.toAction(subject)
        
        XCTAssertEqual(actualValue1?.0, "hello")
        XCTAssertEqual(actualValue1?.1, 42)
        
        let actualValue2 = TestEnum.two.toAction(subject)
        XCTAssertNil(actualValue2)
    }
}
