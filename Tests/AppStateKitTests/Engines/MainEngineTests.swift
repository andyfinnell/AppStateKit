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
    
    private static func doWhat(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
        state.value = "loading"
        
        sideEffects.loadAtIndex(index: 0) {
            .finishBigEffect(value: $0)
        }
    }
    
    private static func finishBigEffect(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, value: String) {
        state.value = value
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
    
    private static func importURL(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, _ url: URL) {
        _ = sideEffects.subscribeToImportURL(url) { content, yield in
            await yield(.finishBigEffect(value: content))
        } onFailure: { error in
            .importFailed("\(error)")
        }
    }
    
    private static func importFailed(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, _ message: String) {
        state.value = message
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
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
        finishExpectation.expectedFulfillmentCount = 2
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }
        
        await subject.send(.doWhat)
        
        await fulfillment(of: [finishExpectation], timeout: 1.0)
        
        let expected = [
            TestComponent.State(value: "loading", lastTick: 0),
            TestComponent.State(value: "loaded index 0", lastTick: 0)
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
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
        finishExpectation.expectedFulfillmentCount = 3
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }

        await subject.send(.beginTimer(count: 3))
        
        await fulfillment(of: [finishExpectation], timeout: 1.0)
        
        let subID = SubscriptionID()
        let expected = [
            TestComponent.State(value: "idle", lastTick: 0, timerID: subID),
            TestComponent.State(value: "idle", lastTick: 1.5, timerID: subID),
            TestComponent.State(value: "idle", lastTick: 3, timerID: subID),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
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
        XCTAssert(uniqueLastTicks.count <= 2 && uniqueLastTicks.count > 0)
        
        _ = sink
    }
    
    func testStartFailableSubscription() async {
        let initialState = TestComponent.State(value: "idle", lastTick: 0)
        let dependencies = DependencyScope()
        let subject = MainEngine(
            dependencies: dependencies,
            state: initialState,
            component: TestComponent.self
        )
        var history = [TestComponent.State]()
        let finishExpectation = expectation(description: "finish")
        let sink = subject.statePublisher.sink { newState in
            history.append(newState)
            
            finishExpectation.fulfill()
        }

        await subject.send(.importURL(URL(string: "https://www.example.com")!))
        
        await fulfillment(of: [finishExpectation], timeout: 1.0)
        
        let expected = [
            TestComponent.State(value: "importFailure", lastTick: 0),
        ]
        XCTAssertEqual(history, expected)
        
        _ = sink
    }

}
