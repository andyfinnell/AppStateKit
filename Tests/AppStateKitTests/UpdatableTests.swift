import Foundation
import XCTest
import AppStateKit

final class UpdatableTests: XCTestCase {
    struct TestStruct: Updatable, Equatable {
        var field: Int
    }
    
    struct TestIdentifiable: Identifiable, Equatable {
        let id: String
        let field: Int
    }
    
    func testUpdateOnStruct() {
        let subject = TestStruct(field: 2).update(\.field, to: 42)
        
        XCTAssertEqual(subject, TestStruct(field: 42))
    }
    
    func testUpdateOnArray() {
        let subject = [1, 2, 3, 4].update(1, to: 42)
        
        XCTAssertEqual(subject, [1, 42, 3, 4])
    }
    
    func testSubscriptOnIdentifiableArray() {
        let subject = [
            TestIdentifiable(id: "one", field: 1),
            TestIdentifiable(id: "two", field: 2),
            TestIdentifiable(id: "three", field: 3),
            TestIdentifiable(id: "four", field: 4)
        ]
        
        XCTAssertEqual(subject[id: "two"], TestIdentifiable(id: "two", field: 2))
        XCTAssertNil(subject[id: "five"])
    }
    
    func testUpdateOnIdentifiableArray() {
        let subject = [
            TestIdentifiable(id: "one", field: 1),
            TestIdentifiable(id: "two", field: 2),
            TestIdentifiable(id: "three", field: 3),
            TestIdentifiable(id: "four", field: 4)
        ]

        let actualValue1 = subject.update("two", to: TestIdentifiable(id: "two", field: 42))
        XCTAssertEqual(actualValue1[1], TestIdentifiable(id: "two", field: 42))
        
        let actualValue2 = subject.update("five", to: TestIdentifiable(id: "five", field: 42))
        XCTAssertEqual(actualValue2, subject)
    }
    
    func testUpdateOnDictionary() {
        let subject = [
            1: "one",
            2: "two",
            3: "three",
            4: "four"
        ]
        
        let actualValue = subject.update(2, to: "fourty two")
        let expected = [
            1: "one",
            2: "fourty two",
            3: "three",
            4: "four"
        ]
        XCTAssertEqual(actualValue, expected)
    }
}
