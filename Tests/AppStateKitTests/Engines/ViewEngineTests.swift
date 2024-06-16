import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

final class ViewEngineTests: XCTestCase {
    @Component
    enum TestComponent {
        struct State: Equatable {
            var value: String
        }
        
        enum Output: Equatable {
            case letParentKnow
        }
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            // nop
        }
        
        private static func updateValue(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, _ value: String) {
            // nop
        }
        
        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            VStack {
                Text(engine.value)
                
                TextField("Label", text: #bind(engine, \.value))
            }
        }
    }
        
    private var parentEngine: FakeEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    private var subject: ViewEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    
    @MainActor 
    override func setUp() {
        super.setUp()
        
        parentEngine = FakeEngine(state: TestComponent.State(value: "idle"))
        subject = ViewEngine(engine: parentEngine, isEqual: ==)
    }

    @MainActor
    func testActionSend() async {
        subject.send(.doWhat)
        
        XCTAssertEqual(parentEngine.sentActions, [.doWhat])
    }
    
    @MainActor
    func testOutputSignal() async {
        subject.signal(.letParentKnow)
        
        XCTAssertEqual(parentEngine.signaledOutput, [.letParentKnow])
    }

    @MainActor
    func testParentStateChanged() {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        parentEngine.state = TestComponent.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestComponent.State(value: "finish"),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }
    
    @MainActor
    func testStateMemberLookup() {
        XCTAssertEqual(subject.value, "idle")
    }
    
    @MainActor
    func testBinding() {
        let binding = subject.binding(\.value, send: { .updateValue($0) })
        
        let stateChanged = expectation(description: "state changed")
        let sink = subject.statePublisher.sink { newState in
            stateChanged.fulfill()
        }

        parentEngine.state = TestComponent.State(value: "changed")

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(binding.wrappedValue, "changed")
        
        let expectation = expectation(description: "sent action")
        parentEngine.sendExpectation = expectation
        binding.wrappedValue = "changed from UI"

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(parentEngine.sentActions, [.updateValue("changed from UI")])
        
        _ = sink
    }
}
