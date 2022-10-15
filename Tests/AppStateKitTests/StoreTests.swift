import Foundation
import Combine
import XCTest
import AppStateKit

fileprivate struct TestReducer: Reducer {
    struct State: Equatable {
        var value: String
    }
    
    enum Action {
        case doWhat
        case finishBigEffect(String)
    }
        
    struct Effects {
        let load: any LoadAtIndexEffect
    }
        
    func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action> {
        switch action {
        case .doWhat:
            state.value = "loading"
            
            return SideEffects {
                effects.load(index: 0) ~> Action.finishBigEffect
            }
            
        case let .finishBigEffect(value):
            state.value = value
            
            return .none()
        }
    }
}

final class StoreTests: XCTestCase {
    
    func testActionApply() async {
        let initialState = TestReducer.State(value: "idle")
        let effects = TestReducer.Effects(load: LoadAtIndexEffectHandler())
        let subject = Store(state: initialState, effects: effects, reducer: TestReducer())
        var cancellables = Set<AnyCancellable>()
        var history = [TestReducer.State]()
        let finishExpectation = expectation(description: "finish")
        
        subject.$state.sink { state in
            history.append(state)
            
            if history.count == 3 {
                finishExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        await subject.apply(.doWhat)
        
        await waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestReducer.State(value: "idle"),
            TestReducer.State(value: "loading"),
            TestReducer.State(value: "loaded index 0")
        ]
        XCTAssertEqual(history, expected)
    }
}
