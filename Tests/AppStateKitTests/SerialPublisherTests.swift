import Foundation
import Combine
import XCTest
import AppStateKit

final class SerialPublisherTests: XCTestCase {
    func testSerialPublisher() {
        let finishExpectation = expectation(description: "finish")
        var cancellables = Set<AnyCancellable>()
        
        let input = Array(1...5)
        var output = [Int]()
        SerialPublisher(input: input, factory: { i -> AnyPublisher<Int, Error> in
            output.append(i)
            
            return Deferred {
                Future { promise in
                    promise(.success(i * 10))
                }.delay(for: .milliseconds((5 - i) * 250), scheduler: RunLoop.main)
                
            }.eraseToAnyPublisher()
        }).sink(receiveCompletion: { completion in
            finishExpectation.fulfill()
        }, receiveValue: { value in
            output.append(value)
        }).store(in: &cancellables)
        
        waitForExpectations(timeout: 10.0, handler: nil)
        
        XCTAssertEqual(output, [1, 10, 2, 20, 3, 30, 4, 40, 5, 50])
    }
}
