import Foundation
import XCTest
@testable import AppStateKit
import SwiftUI

@Component
fileprivate enum TestComponent {
    struct State: Equatable {
        var value: String
        var lastTick: TimeInterval
        var timerID: SubscriptionID?
        
        static func ==(lhs: State, rhs: State) -> Bool {
            lhs.value == rhs.value
            && lhs.lastTick == rhs.lastTick
            && (lhs.timerID != nil) == (rhs.timerID != nil)
        }
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
    
    private static func onTick(_ state: inout State, sideEffects: AnySideEffects<Action>, _ timestamp: TimeInterval) {
        state.lastTick = timestamp
    }
    
    private static func beginTimer(_ state: inout State, sideEffects: AnySideEffects<Action>, count: Int) {
        state.timerID = sideEffects.subscribe(\.timer, with: 1.5, count) { timestamps, yield in
            for await timestamp in timestamps {
                try Task.checkCancellation()
                await yield(.onTick(timestamp))
            }
        }
    }
    
    private static func stopTimer(_ state: inout State, sideEffects: AnySideEffects<Action>) {
        guard let timerID = state.timerID else {
            return
        }
        sideEffects.cancel(timerID)
        state.timerID = nil
    }
    
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        Text(engine.value)
    }
}

final class MainEngineTests: XCTestCase {
    
    func testActionSend() async {
        let initialState = TestComponent.State(value: "idle", lastTick: 0)
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
            TestComponent.State(value: "idle", lastTick: 0),
            TestComponent.State(value: "loading", lastTick: 0),
            TestComponent.State(value: "loaded index 0", lastTick: 0)
        ]
        XCTAssertEqual(history, expected)
    }

    func testStartSubscription() async {
        let initialState = TestComponent.State(value: "idle", lastTick: 0)
        let dependencies = DependencyScope()
        let subject = MainEngine(
            dependencies: dependencies,
            state: initialState,
            component: TestComponent.self
        )
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        finishExpectation.expectedFulfillmentCount = 5
        startObserving {
            subject.state
        } onChange: { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        await subject.send(.beginTimer(count: 3))
        
        await fulfillment(of: [finishExpectation])
        
        let subID = SubscriptionID()
        let expected = [
            TestComponent.State(value: "idle", lastTick: 0, timerID: nil),
            TestComponent.State(value: "idle", lastTick: 0, timerID: subID),
            TestComponent.State(value: "idle", lastTick: 0, timerID: subID),
            TestComponent.State(value: "idle", lastTick: 1.5, timerID: subID),
            TestComponent.State(value: "idle", lastTick: 3, timerID: subID),
        ]
        XCTAssertEqual(history, expected)
    }

    func testCancelSubscription() async {
        let initialState = TestComponent.State(value: "idle", lastTick: 0)
        let dependencies = DependencyScope()
        let subject = MainEngine(
            dependencies: dependencies,
            state: initialState,
            component: TestComponent.self
        )
        var history = [TestComponent.State]()
        let isGoingExpectation = expectation(description: "is going")
        let hasStopped = expectation(description: "has stopped")
        startObserving {
            subject.state
        } onChange: { newState in
            let previousState = history.last
            history.append(newState)
            
            if history.count == 5 {
                isGoingExpectation.fulfill()
            }
            if let previousState, previousState.timerID != nil && newState.timerID == nil {
                hasStopped.fulfill()
            }
        }
        
        await subject.send(.beginTimer(count: 1000))
        
        // Wait until we know we've started the subscription
        await fulfillment(of: [isGoingExpectation], timeout: 1.0)
        
        await subject.send(.stopTimer)
        
        // Wait until we see the timer go nil
        await fulfillment(of: [hasStopped], timeout: 1.0)

        // We should see timerID go nil and no more advancement of lastTick
        guard let lastTimerIndex = history.lastIndex(where: { $0.timerID != nil }) else {
            XCTFail("Timer never stopped or started")
            return
        }
        
        let endOfHistory = history[history.index(after: lastTimerIndex)..<history.endIndex]
        let uniqueLastTicks = Set(endOfHistory.map { $0.lastTick })
        XCTAssertEqual(uniqueLastTicks.count, 1)
    }
}
