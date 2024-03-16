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
                
    func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        switch action {
        case .doWhat:
            state.value = "loading"
            
            sideEffects.perform(\.loadAtIndex, with: 0) {
                .finishBigEffect($0)
            }
            
        case let .finishBigEffect(value):
            state.value = value
        }
    }
}

final class StoreTests: XCTestCase {
    
    func testActionApply() async {
        let initialState = TestReducer.State(value: "idle")
        let dependencies = DependencyScope()
        let subject = Store(dependencies: dependencies, state: initialState, reducer: TestReducer())
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
        
        await fulfillment(of: [finishExpectation])
        
        let expected = [
            TestReducer.State(value: "idle"),
            TestReducer.State(value: "loading"),
            TestReducer.State(value: "loaded index 0")
        ]
        XCTAssertEqual(history, expected)
    }
}
