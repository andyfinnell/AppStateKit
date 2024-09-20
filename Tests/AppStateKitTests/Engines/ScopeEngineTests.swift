import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

final class ScopeEngineTests: XCTestCase {
    @Component
    enum ParentComponent {
        struct State: Equatable {
            var count: Int
            var isFinished: Bool
        }
        
        private static func increment(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            state.count += 1
        }
        
        private static func markFinished(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            state.isFinished = true
        }
        
        @Detachment
        enum Test {
            static func initialState(_ state: State) -> TestComponent.State {
                TestComponent.State(count: state.count, value: "idle", lastTick: 0)
            }
            
            static func actionToUpdateState(from state: State) -> TestComponent.Action? {
                .updateCount(state.count)
            }
            
            static func translate(from output: TestComponent.Output) -> Action? {
                switch output {
                case .markFinished:
                    return .markFinished
                }
            }
        }
        
        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            VStack {
                Text("Count: \(engine.count)")
                
                test(engine)
            }
        }
    }
    
    @Component
    enum TestComponent {
        struct State: Equatable {
            var count: Int
            var value: String
            var lastTick: TimeInterval
            var timerID: SubscriptionID?
            
            static func ==(lhs: State, rhs: State) -> Bool {
                lhs.count == rhs.count
                && lhs.value == rhs.value
                && lhs.lastTick == rhs.lastTick
                && (lhs.timerID != nil) == (rhs.timerID != nil)
            }
        }
        
        enum Output: Hashable {
            case markFinished
        }
        
        private static func updateCount(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, _ count: Int) {
            state.count = count
        }
        
        private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            state.value = "loading"
            
            sideEffects.loadAtIndex(index: 0) {
                .finishBigEffect(value: $0)
            }
        }
        
        private static func finishBigEffect(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, value: String) {
            state.value = value
            if state.value == "finished" {
                sideEffects.signal(.markFinished)
            }
        }
        
        private static func onTick(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, _ timestamp: TimeInterval) {
            state.lastTick = timestamp
        }
        
        private static func beginTimer(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, count: Int) {
            state.timerID = sideEffects.subscribeToTimer(delay: 1.5, count: count) { timestamps, yield in
                for await timestamp in timestamps {
                    try Task.checkCancellation()
                    await yield(.onTick(timestamp))
                }
            }
        }
        
        private static func stopTimer(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
            guard let timerID = state.timerID else {
                return
            }
            sideEffects.cancel(timerID)
            state.timerID = nil
        }
        
        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            Text(engine.value)
        }
    }

    private var parentEngine: FakeEngine<ParentComponent.State, ParentComponent.Action, ParentComponent.Output>!
    private var subject: ScopeEngine<TestComponent.State, TestComponent.Action, TestComponent.Output>!
    
    override func setUp() async throws {
        try await super.setUp()
    
        parentEngine = await FakeEngine(state: ParentComponent.State(count: 0, isFinished: false))
        subject = await parentEngine.scope(
            component: TestComponent.self,
            initialState: ParentComponent.Test.initialState,
            actionToUpdateState: ParentComponent.Test.actionToUpdateState,
            translate: ParentComponent.Test.translate,
            inject: { _ in  }
        )
    }

    @MainActor
    func testActionSend() async {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        finishExpectation.expectedFulfillmentCount = 2
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        subject.send(.doWhat)
        
        await fulfillment(of: [finishExpectation], timeout: 1.0)
        
        let expected = [
            TestComponent.State(count: 0, value: "loading", lastTick: 0),
            TestComponent.State(count: 0, value: "loaded index 0", lastTick: 0)
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }

    @MainActor
    func testStartSubscription() async {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        finishExpectation.expectedFulfillmentCount = 3
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }

        subject.send(.beginTimer(count: 3))
        
        await fulfillment(of: [finishExpectation], timeout: 1.0)
        
        let subID = SubscriptionID()
        let expected = [
            TestComponent.State(count: 0, value: "idle", lastTick: 0, timerID: subID),
            TestComponent.State(count: 0, value: "idle", lastTick: 1.5, timerID: subID),
            TestComponent.State(count: 0, value: "idle", lastTick: 3, timerID: subID),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }

    @MainActor
    func testCancelSubscription() async {
        var history = [TestComponent.State]()
        let isGoingExpectation = expectation(description: "is going")
        let hasStopped = expectation(description: "has stopped")
        let sink = subject.statePublisher.sink { newState in
            let previousState = history.last
            history.append(newState)
            
            if history.count == 5 {
                isGoingExpectation.fulfill()
            }
            if let previousState, previousState.timerID != nil && newState.timerID == nil {
                hasStopped.fulfill()
            }
        }
        
        subject.send(.beginTimer(count: 1000))
        
        // Wait until we know we've started the subscription
        await fulfillment(of: [isGoingExpectation], timeout: 1.0)
        
        subject.send(.stopTimer)
        
        // Wait until we see the timer go nil
        await fulfillment(of: [hasStopped], timeout: 1.0)

        // We should see timerID go nil and no more advancement of lastTick
        guard let lastTimerIndex = history.lastIndex(where: { $0.timerID != nil }) else {
            XCTFail("Timer never stopped or started")
            return
        }
        
        let endOfHistory = history[history.index(after: lastTimerIndex)..<history.endIndex]
        let uniqueLastTicks = Set(endOfHistory.map { $0.lastTick })
        XCTAssert(uniqueLastTicks.count > 0 && uniqueLastTicks.count <= 2)
        
        _ = sink
    }
    
    @MainActor
    func testTranslateOutput() async {
        subject.signal(.markFinished)
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.markFinished])
    }

    @MainActor
    func testTranslateOutputThroughSideEffects() async {
        subject.send(.finishBigEffect(value: "finished"))
        
        XCTAssertEqual(parentEngine.sentActions, [ParentComponent.Action.markFinished])
    }

    @MainActor
    func testParentStateChanged() {
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        parentEngine.state = ParentComponent.State(count: 2, isFinished: false)
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestComponent.State(count: 2, value: "idle", lastTick: 0, timerID: nil),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }

}
