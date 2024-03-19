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
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action>) {
            // nop
        }
        
        private static func valueDidChange(_ state: inout State, sideEffects: AnySideEffects<Action>, _ value: String) {
            // nop
        }
        
        static func view(_ engine: ViewEngine<State, Action>) -> some View {
            Text(engine.value)
        }
    }
        
    private var parentEngine: FakeEngine<TestComponent.State, TestComponent.Action>!
    private var subject: ViewEngine<TestComponent.State, TestComponent.Action>!
    
    override func setUp() {
        super.setUp()
        
        parentEngine = FakeEngine(state: TestComponent.State(value: "idle"))
        subject = ViewEngine(engine: parentEngine)
    }

    func testActionApply() async {
        await subject.send(.doWhat)
        
        XCTAssertEqual(parentEngine.sentActions, [.doWhat])
    }

    func testParentStateChanged() {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        
        startObserving {
            self.subject.state
        } onChange: { newState in
            history.append(newState)
            
            if history.count == 2 {
                finishExpectation.fulfill()
            }
        }
        
        parentEngine.state = TestComponent.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestComponent.State(value: "idle"),
            TestComponent.State(value: "finish"),
        ]
        XCTAssertEqual(history, expected)
    }
    
    @MainActor
    func testStateMemberLookup() {
        XCTAssertEqual(subject.value, "idle")
    }
    
    @MainActor
    func testBinding() {
        let binding = subject.binding(\.value, send: { .valueDidChange($0) })
        
        let stateChanged = expectation(description: "state changed")
        startObserving {
            self.subject.state
        } onChange: { newState in
            stateChanged.fulfill()
        }

        parentEngine.state = TestComponent.State(value: "changed")

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(binding.wrappedValue, "changed")
        
        let expectation = expectation(description: "sent action")
        startObserving {
            self.parentEngine.sentActions
        } onChange: { newState in
            expectation.fulfill()
        }

        binding.wrappedValue = "changed from UI"

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(parentEngine.sentActions, [.valueDidChange("changed from UI")])
    }
}
