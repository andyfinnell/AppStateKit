import Foundation
import XCTest
import AppStateKit
import Combine

final class ViewStoreTests: XCTestCase {
    enum TestModule {
        struct State: Updatable, Equatable {
            var value: String
        }
        
        enum Action: Equatable {
            case doWhat
            case valueDidChange(String)
        }
    }
        
    private var parentStore: FakeStore<TestModule.State, TestModule.Action>!
    private var subject: ViewStore<TestModule.State, TestModule.Action>!
    
    override func setUp() {
        super.setUp()
        
        parentStore = FakeStore(state: TestModule.State(value: "idle"))
        subject = ViewStore(store: parentStore)
    }

    func testActionApply() {
        subject.apply(.doWhat)
        
        XCTAssertEqual(parentStore.appliedActions, [.doWhat])
    }

    func testParentStateChanged() {
        var cancellables = Set<AnyCancellable>()
        var history = [TestModule.State]()
        let finishExpectation = expectation(description: "finish")
        
        subject.$state.sink { state in
            history.append(state)
            
            if history.count == 2 {
                finishExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        parentStore.currentState.value = TestModule.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestModule.State(value: "idle"),
            TestModule.State(value: "finish"),
        ]
        XCTAssertEqual(history, expected)
    }
    
    func testStateMemberLookup() {
        XCTAssertEqual(subject.value, "idle")
    }
    
    func testBinding() {
        let binding = subject.binding(\.value, apply: { .valueDidChange($0) })
        
        parentStore.currentState.value = TestModule.State(value: "changed")
        
        XCTAssertEqual(binding.wrappedValue, "changed")
        
        binding.wrappedValue = "changed from UI"
        
        XCTAssertEqual(parentStore.appliedActions, [.valueDidChange("changed from UI")])
    }
}
