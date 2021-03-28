import Foundation
import XCTest
import AppStateKit

final class ExtractableTests: XCTestCase {
    enum TestEnum: Extractable {
        case one(String, Int)
        case two(Float)
    }
    
    func testExtract() {
        let subject = TestEnum.one("hello", 42)
        let actualValue1 = subject.extract(TestEnum.one)
        
        XCTAssertEqual(actualValue1?.0, "hello")
        XCTAssertEqual(actualValue1?.1, 42)
        
        let actualValue2 = subject.extract(TestEnum.two)
        XCTAssertNil(actualValue2)
    }
    
    func testExtractor() {
        let extractor = TestEnum.extractor(TestEnum.one)
        let subject1 = TestEnum.one("hello", 42)
        let actualValue1 = extractor(subject1)
        
        XCTAssertEqual(actualValue1?.0, "hello")
        XCTAssertEqual(actualValue1?.1, 42)

        let subject2 = TestEnum.two(1.234)
        let actualValue2 = extractor(subject2)
        XCTAssertNil(actualValue2)
    }
}
