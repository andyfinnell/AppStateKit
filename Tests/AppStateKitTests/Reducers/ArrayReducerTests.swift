import Foundation
import XCTest
@testable import AppStateKit

final class ArrayReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: [ChildState]
    }
    
    @BindableAction
    enum ParentAction: Hashable {
        case child(ChildAction, Int)
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
                    ChildAction.saved
                }
                
            case .saved:
                state.value = "done"
            }
        }
        
        let subject = ArrayReducer<ParentState, ParentAction>(
            state: \ParentState.child,
            action: ParentAction.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: [
            ChildState(value: "idle1"),
            ChildState(value: "idle2"),
            ChildState(value: "idle3")
        ])
        let dependencies = DependencyScope()
        let sideEffects = SideEffectsContainer<ParentAction>(dependencyScope: dependencies)
        subject.reduce(
            &state,
            action: .child(.save("thing"), 1),
            sideEffects: sideEffects.eraseToAnySideEffects()
        )
        
        let expectedState = ParentState(child: [
            ChildState(value: "idle1"),
            ChildState(value: "thing"),
            ChildState(value: "idle3")
        ])
        XCTAssertEqual(state, expectedState)
        
        // Verify the effects
        let actualActions = await testMaterializeEffects(sideEffects)
        let expectedActions = Set<ParentAction>([
            .child(.saved, 1)
        ])
        XCTAssertEqual(actualActions, expectedActions)
    }

}
