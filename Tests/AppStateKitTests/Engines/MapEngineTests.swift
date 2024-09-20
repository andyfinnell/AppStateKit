import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

final class MapEngineTests: XCTestCase {
    @Component
    enum ParentComponent {
        struct State: Equatable {
            var value: String
            var test: TestComponent.State {
                get {
                    TestComponent.State(isOn: value == "finish")
                }
                set {
                    if newValue.isOn {
                        value = "finish"
                    } else {
                        value = "begin"
                    }
                }
            }
        }
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            
        }

        private static func finishBigEffect(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            
        }

        private static func translateTest(from output: TestComponent.Output) -> Action? {
            .finishBigEffect
        }
        
        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            VStack {
                Text(engine.value)
                
                test(engine)
            }
        }
    }
    
    @Component
    enum TestComponent {
        struct State: Equatable {
            var isOn: Bool
        }
        
        enum Output: Equatable {
            case letParentKnow
        }
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            
        }

        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            Text(engine.isOn ? "On" : "Off")
        }
    }
    
    private var parentEngine: FakeEngine<ParentComponent.State, ParentComponent.Action, ParentComponent.Output>!
    private var subject: MapEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        parentEngine = await FakeEngine(state: ParentComponent.State(value: "idle"))
        subject = await parentEngine.map(
            state: { $0.test },
            action: ParentComponent.Action.test,
            translate: { _ in .finishBigEffect }
        )
    }

    @MainActor
    func testActionSend() async {
        subject.send(.doWhat)
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.test(.doWhat)])
    }

    @MainActor
    func testOutputSignal() async {
        subject.signal(.letParentKnow)
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.finishBigEffect])
    }

    @MainActor
    func testParentStateChanged() {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        parentEngine.state = ParentComponent.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestComponent.State(isOn: true),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }
}
