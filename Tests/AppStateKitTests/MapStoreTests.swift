import Foundation
import XCTest
import AppStateKit
import Combine

final class MapStoreTests: XCTestCase {
    enum ParentModule {
        struct State: Updatable, Equatable {
            var value: String
        }
        
        enum Action {
            case doWhat
            case finishBigEffect
        }
    }
    
    enum TestModule {
        struct State: Updatable, Equatable {
            var isOn: Bool
        }
        
        enum Action {
            case doWhat
        }
    }
    
    private var parentStore: FakeStore<ParentModule.State, ParentModule.Action>!
    private var subject: MapStore<TestModule.State, TestModule.Action>!
    
    override func setUp() {
        super.setUp()
        
        parentStore = FakeStore(state: ParentModule.State(value: "idle"))
        subject = parentStore.map(toLocalState: {
            TestModule.State(isOn: $0.value == "finish")
        }, fromLocalAction: { (action: TestModule.Action) -> ParentModule.Action in
            switch action {
            case .doWhat: return .doWhat
            }
        })
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
        
        parentStore.currentState.value = ParentModule.State(value: "finish")
        
        waitForExpectations(timeout: 1, handler: nil)
        
        let expected = [
            TestModule.State(isOn: false),
            TestModule.State(isOn: true),
        ]
        XCTAssertEqual(history, expected)
    }
}
