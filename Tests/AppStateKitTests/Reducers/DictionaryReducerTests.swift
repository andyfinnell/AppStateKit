import Foundation
import XCTest
@testable import AppStateKit

final class DictionaryReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: [String: ChildState]
    }
    
    enum ParentAction: Extractable, Hashable {
        case child(ChildAction, String)
    }
            
    struct ChildState: Equatable {
        var value: String
    }
    
    enum ChildAction: Hashable {
        case save(String)
        case saved
    }
    
    func testInBounds() async {
        let child = AnonymousReducer<ChildState, ChildAction> { state, action, sideEffects in
            switch action {
            case let .save(value):
                state.value = value
                sideEffects.perform(\.save, with: 0, value) {
                    .saved
                }
                
            case .saved:
                state.value = "done"
            }
        }
        
        let subject = DictionaryReducer<ParentState, ParentAction>(
            state: \ParentState.child,
            action: ActionBinding(ParentAction.child)) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: [
            "one": ChildState(value: "idle1"),
            "two": ChildState(value: "idle2"),
            "three": ChildState(value: "idle3")
        ])
        let dependencies = DependencyScope()
        let sideEffects = SideEffectsContainer<ParentAction>(dependencyScope: dependencies)
        subject.reduce(
            &state,
            action: .child(.save("thing"), "two"),
            sideEffects: sideEffects.eraseToAnySideEffects()
        )
        
        let expectedState = ParentState(child: [
            "one": ChildState(value: "idle1"),
            "two": ChildState(value: "thing"),
            "three": ChildState(value: "idle3")
        ])
        XCTAssertEqual(state, expectedState)
        
        // Verify the effects
        let actualActions = await testMaterializeEffects(sideEffects)
        let expectedActions = Set<ParentAction>([
            .child(.saved, "two")
        ])
        XCTAssertEqual(actualActions, expectedActions)
    }

}
