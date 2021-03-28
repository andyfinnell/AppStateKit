import Foundation
import XCTest
import Combine
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
    
    enum Effect: Equatable {
        case causes(Action)
        case subeffect(SubEffect)
    }
    
    enum SubEffect: Equatable {
        case subcause(Action)
    }
    
    enum Action: Equatable {
        case one, two, three
    }
    
    func testSerialEffects() {
        var cancellables = Set<AnyCancellable>()
        let finishExpectation = expectation(description: "finish")
        var output = [Action]()
        let subject = SideEffects<Effect>()
        
        subject(.causes(.one), .causes(.two))
        
        subject.apply(using: SideEffectsTests.effectToAction).sink(receiveCompletion: { completion in
            finishExpectation.fulfill()
        }, receiveValue: { action in
            output.append(action)
        }).store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Should always be in this order
        XCTAssertEqual(output, [.one, .two])
    }
    
    func testParallelEffects() {
        var cancellables = Set<AnyCancellable>()
        let finishExpectation = expectation(description: "finish")
        var output = Set<Action>()
        let subject = SideEffects<Effect>()
        
        subject(.causes(.one))
        subject(.causes(.two))
        subject(.causes(.three))

        subject.apply(using: SideEffectsTests.effectToAction).sink(receiveCompletion: { completion in
            finishExpectation.fulfill()
        }, receiveValue: { action in
            output.insert(action)
        }).store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // These can be in any order
        XCTAssertEqual(output, Set([.one, .two, .three]))
    }
    
    func testCombinedEffects() {
        var cancellables = Set<AnyCancellable>()
        let finishExpectation = expectation(description: "finish")
        var output = Set<Action>()
        let subject = SideEffects<Effect>()
        
        subject(.causes(.one), .causes(.two))
        
        let localSubject = SideEffects<SubEffect>()
        localSubject(.subcause(.three))
        subject.combine(localSubject, using: Effect.subeffect)
        
        subject.apply(using: SideEffectsTests.effectToAction).sink(receiveCompletion: { completion in
            finishExpectation.fulfill()
        }, receiveValue: { action in
            output.insert(action)
        }).store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // These can be in any order
        XCTAssertEqual(output, Set([.one, .two, .three]))
    }


    private static func effectToAction(_ effect: Effect) -> AnyPublisher<Action, Never> {
        switch effect {
        case let .causes(action):
            return Just(action).eraseToAnyPublisher()
        case let .subeffect(subeffect):
            switch subeffect {
            case let .subcause(action):
                return Just(action).eraseToAnyPublisher()
            }
        }
    }
}
