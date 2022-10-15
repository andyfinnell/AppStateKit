import Foundation
import XCTest
import AppStateKit
import Combine

final class MapStoreTests: XCTestCase {
    enum ParentReducer {
        struct State: Equatable {
            var value: String
        }
        
        enum Action {
            case doWhat
            case finishBigEffect
        }
    }
    
    enum TestReducer {
        struct State: Equatable {
            var isOn: Bool
        }
        
        enum Action {
            case doWhat
        }
    }
    
    private var parentStore: FakeStore<ParentReducer.State, ParentReducer.Action>!
    private var subject: MapStore<TestReducer.State, TestReducer.Action>!
    
    override func setUp() {
        super.setUp()
        
        parentStore = FakeStore(state: ParentReducer.State(value: "idle"))
        subject = parentStore.map(state: {
            TestReducer.State(isOn: $0.value == "finish")
        }, action: { (action: TestReducer.Action) -> ParentReducer.Action in
            switch action {
            case .doWhat: return .doWhat
            }
        })
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
        
        parentStore.currentState.value = ParentReducer.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestReducer.State(isOn: false),
            TestReducer.State(isOn: true),
        ]
        XCTAssertEqual(history, expected)
    }
}
