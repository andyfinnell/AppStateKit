import Foundation
import Combine
import XCTest
import AppStateKit

fileprivate struct TestModule: UIModule {
    struct State: Updatable, Equatable {
        var value: String
    }
    
    enum Action {
        case doWhat
        case finishBigEffect
    }
    
    enum Effect {
        case big
    }
    
    struct Environment {
        let globalValue: String
    }
    
    static func performSideEffect(_ effect: Effect, in environment: Environment) -> AnyPublisher<Action, Never> {
        switch effect {
        case .big:
            return Just(Action.finishBigEffect).eraseToAnyPublisher()
        }
    }
    
    static func reduce(_ state: State, action: Action, sideEffects: SideEffects<Effect>) -> State {
        switch action {
        case .doWhat:
            sideEffects(.big)
            
            return state.update(\.value, to: "loading")
            
        case .finishBigEffect:
            
            return state.update(\.value, to: "big effect")
        }
    }
    
    static var value: UIModuleValue<State, Action, Effect, Environment> { internalValue }
}

final class StoreTests: XCTestCase {
    
    func testActionApply() {
        let env = TestModule.Environment(globalValue: "bob")
        let initialState = TestModule.State(value: "idle")
        let subject = TestModule.makeStore(initialState: initialState, environment: env)
        var cancellables = Set<AnyCancellable>()
        var history = [TestModule.State]()
        let finishExpectation = expectation(description: "finish")
        
        subject.$state.sink { state in
            history.append(state)
            
            if history.count == 3 {
                finishExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        subject.apply(.doWhat)
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestModule.State(value: "idle"),
            TestModule.State(value: "loading"),
            TestModule.State(value: "big effect")
        ]
        XCTAssertEqual(history, expected)
    }
}
