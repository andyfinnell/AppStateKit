import Foundation
import XCTest
@testable import AppStateKit

final class PropertyReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: ChildState
    }
    
    @BindableAction
    enum ParentAction: Hashable {
        case child(ChildAction)
    }
            
    struct ChildState: Equatable {
        var value: String
    }
    
    enum ChildAction: Hashable {
        case save(String)
        case saved
    }
    
    func testProperty() async {
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
        
        let subject = PropertyReducer<ParentState, ParentAction>(
            state: \ParentState.child,
            action: ParentAction.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: ChildState(value: "idle"))
        let dependencies = DependencyScope()
        let sideEffects = SideEffectsContainer<ParentAction>(dependencyScope: dependencies)
        subject.reduce(
            &state,
            action: .child(.save("thing")),
            sideEffects: sideEffects.eraseToAnySideEffects()
        )
        
        XCTAssertEqual(state, ParentState(child: ChildState(value: "thing")))
        
        // Verify the effects
        let actualActions = await testMaterializeEffects(sideEffects)
        let expectedActions = Set<ParentAction>([
            .child(.saved)
        ])
        XCTAssertEqual(actualActions, expectedActions)
    }

}
