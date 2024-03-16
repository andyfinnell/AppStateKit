import Foundation
import XCTest
@testable import AppStateKit

final class LiftReducerTests: XCTestCase {
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
    
    func testLift() async {
        let child = AnonymousReducer<ChildState, ChildAction> { state, action, sideEffects in
            switch action {
            case let .save(value):
                state.value = value
                
                sideEffects.perform(\.save, with: 0, value) { _ in
                    ChildAction.saved
                }
                
            case .saved:
                state.value = "done"
            }
        }
        
        let subject = LiftReducer(action: ParentAction.child) {
            child
        }
        
        
        // Verify the reducer
        var state = ChildState(value: "idle")
        let dependencies = DependencyScope()
        let sideEffects = SideEffectsContainer<ParentAction>(dependencyScope: dependencies)
        subject.reduce(
            &state,
            action: ParentAction.child(.save("thing")),
            sideEffects: sideEffects.eraseToAnySideEffects()
        )
        
        XCTAssertEqual(state, ChildState(value: "thing"))
        
        // Verify the effects
        let actualActions = await testMaterializeEffects(sideEffects)
        let expectedActions = Set<ParentAction>([
            .child(.saved)
        ])
        XCTAssertEqual(actualActions, expectedActions)
    }

}
