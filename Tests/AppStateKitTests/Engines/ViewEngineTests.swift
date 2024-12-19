import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

final class ViewEngineTests: XCTestCase {
    @Component
    enum TestComponent {
        struct State: Equatable {
            var value: String
            var toggles: [Bool] = [true, false, true, false]
            var flags: [Bool] = [true, false, true, false]
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
        
        private static func updateToggles(_ state: inout State, sideEffects: SideEffects, _ toggle: Bool, index: Int) {
            guard index >= state.toggles.startIndex && index < state.toggles.endIndex else {
                return
            }
            state.toggles[index] = toggle
        }

        private static func updateFlags(_ state: inout State, sideEffects: SideEffects, _ flags: [Int: Bool]) {
            for (i, flag) in flags {
                state.flags[i] = flag
            }
        }

        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            VStack {
                Text(engine.value)
                
                TextField("Label", text: #bind(engine, \.value))
                
                Toggle("Toggles", sources: #bindElements(engine, \.toggles), isOn: \.self)
            }
        }
    }
        
    private var parentEngine: FakeEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    private var subject: ViewEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        parentEngine = await FakeEngine(state: TestComponent.State(value: "idle"))
        subject = await ViewEngine(engine: parentEngine, isEqual: ==)
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
    
    @MainActor
    func testBindingElements() {
        let bindings = subject.binding(\.toggles, send: { .updateToggles($0, index: $1) })
        
        let expectation = expectation(description: "sent action")
        parentEngine.sendExpectation = expectation
        bindings[1].wrappedValue = true

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(parentEngine.sentActions, [.updateToggles(true, index: 1)])
    }
    
    @MainActor
    func testBindingBatch() {
        let bindings = subject.binding(\.flags, send: { .updateFlags($0) })
        
        let expectation = expectation(description: "sent action")
        parentEngine.sendExpectation = expectation
        bindings[1].wrappedValue = true
        bindings[3].wrappedValue = true

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(parentEngine.sentActions, [.updateFlags([1: true, 3: true])])
    }

}
