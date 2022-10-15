import Foundation
import XCTest
import AppStateKit
import Combine

@MainActor
final class ViewStoreTests: XCTestCase {
    enum TestReducer {
        struct State: Equatable {
            var value: String
        }
        
        enum Action: Equatable {
            case doWhat
            case valueDidChange(String)
        }
    }
        
    private var parentStore: FakeStore<TestReducer.State, TestReducer.Action>!
    private var subject: ViewStore<TestReducer.State, TestReducer.Action>!
    
    override func setUp() {
        super.setUp()
        
        parentStore = FakeStore(state: TestReducer.State(value: "idle"))
        subject = ViewStore(store: parentStore)
    }

    func testActionApply() async {
        await subject.apply(.doWhat)
        
        XCTAssertEqual(parentStore.appliedActions, [.doWhat])
    }

    func testParentStateChanged() {
        var cancellables = Set<AnyCancellable>()
        var history = [TestReducer.State]()
        let finishExpectation = expectation(description: "finish")
        
        subject.$state.sink { state in
            history.append(state)
            
            if history.count == 2 {
                finishExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        parentStore.currentState.value = TestReducer.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestReducer.State(value: "idle"),
            TestReducer.State(value: "finish"),
        ]
        XCTAssertEqual(history, expected)
    }
    
    func testStateMemberLookup() {
        XCTAssertEqual(subject.value, "idle")
    }
    
    func testBinding() async {
        let binding = subject.binding(\.value, apply: { .valueDidChange($0) })
        
        parentStore.currentState.value = TestReducer.State(value: "changed")
        
        XCTAssertEqual(binding.wrappedValue, "changed")
        
        binding.wrappedValue = "changed from UI"

        await pollUntil(!self.parentStore.appliedActions.isEmpty)
        
        XCTAssertEqual(parentStore.appliedActions, [.valueDidChange("changed from UI")])
    }
    
    func pollUntil(_ predicate: @autoclosure @escaping () -> Bool, timeout: TimeInterval = 30.0) async {
        let doneDate = Date(timeIntervalSinceNow: timeout)
        while !predicate() && Date() <= doneDate {
            await Task.yield()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }
}
