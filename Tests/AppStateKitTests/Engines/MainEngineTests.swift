import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

@Component
fileprivate enum TestComponent {
    struct State: Equatable {
        var value: String
    }
    
    private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action>) {
        state.value = "loading"
        
        sideEffects.perform(\.loadAtIndex, with: 0) {
            .finishBigEffect(value: $0)
        }
    }
    
    private static func finishBigEffect(_ state: inout State, sideEffects: AnySideEffects<Action>, value: String) {
        state.value = value
    }
    
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        Text(engine.value)
    }
}

final class MainEngineTests: XCTestCase {
    
    func testActionSend() async {
        let initialState = TestComponent.State(value: "idle")
        let dependencies = DependencyScope()
        let subject = MainEngine(
            dependencies: dependencies,
            state: initialState,
            component: TestComponent.self
        )
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        
        startObserving {
            subject.state
        } onChange: { newState in
            history.append(newState)
            
            if history.count == 3 {
                finishExpectation.fulfill()
            }
        }
        
        await subject.send(.doWhat)
        
        await fulfillment(of: [finishExpectation])
        
        let expected = [
            TestComponent.State(value: "idle"),
            TestComponent.State(value: "loading"),
            TestComponent.State(value: "loaded index 0")
        ]
        XCTAssertEqual(history, expected)
    }
}
