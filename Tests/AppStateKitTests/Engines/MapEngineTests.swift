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
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action>) {
            
        }

        private static func finishBigEffect(_ state: inout State, sideEffects: AnySideEffects<Action>) {
            
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
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action>) {
            
        }

        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            Text(engine.isOn ? "On" : "Off")
        }
    }
    
    private var parentEngine: FakeEngine<ParentComponent.State, ParentComponent.Action, ParentComponent.Output>!
    private var subject: MapEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    
    override func setUp() {
        super.setUp()
        
        parentEngine = FakeEngine(state: ParentComponent.State(value: "idle"))
        subject = parentEngine.map(
            state: { $0.test },
            action: ParentComponent.Action.test,
            translate: { _ in .finishBigEffect }
        )
    }

    func testActionSend() async {
        await subject.send(.doWhat)
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.test(.doWhat)])
    }

    func testOutputSignal() async {
        await subject.signal(.letParentKnow)
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.finishBigEffect])
    }

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
