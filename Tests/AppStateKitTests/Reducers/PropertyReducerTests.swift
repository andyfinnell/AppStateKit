import Foundation
import XCTest
@testable import AppStateKit

final class PropertyReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: ChildState
    }
    
    enum ParentAction: Extractable, Hashable {
        case child(ChildAction)
    }
        
    struct ParentEffects {
        let loadAtIndex: Effect<String, Never, Int>
        let save: Effect<Void, Never, Int, String>
        
        var child: ChildEffects {
            ChildEffects(save: save)
        }
    }
    
    struct ChildState: Equatable {
        var value: String
    }
    
    enum ChildAction: Hashable {
        case save(String)
        case saved
    }

    struct ChildEffects {
        let save: Effect<Void, Never, Int, String>
    }
    
    func testProperty() async {
        let child = AnonymousReducer<ChildState, ChildAction, ChildEffects> { state, action, effects, sideEffects in
            switch action {
            case let .save(value):
                state.value = value
                
                sideEffects.perform(effects.save, with: 0, value) {
                    .saved
                }
                
            case .saved:
                state.value = "done"
            }
        }
        
        let subject = PropertyReducer<ParentState, ParentAction, ParentEffects>(
            state: \ParentState.child,
            action: ActionBinding(ParentAction.child),
            effects: \ParentEffects.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: ChildState(value: "idle"))
        let dependencies = DependencySpace()
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                                    save: SaveEffect.makeDefault(with: dependencies))
        let sideEffects = SideEffectsContainer<ParentAction>()
        subject.reduce(
            &state,
            action: .child(.save("thing")),
            effects: effects,
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
