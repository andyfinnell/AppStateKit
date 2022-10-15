import Foundation
import XCTest
@testable import AppStateKit

final class IdentifiableReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: [ChildState]
    }
    
    enum ParentAction: Extractable, Hashable {
        case child(ChildAction, ChildState.ID)
    }
        
    struct ParentEffects {
        let loadAtIndex: any LoadAtIndexEffect
        let save: any SaveEffect
        
        var child: ChildEffects {
            ChildEffects(save: save)
        }
    }
    
    struct ChildState: Equatable, Identifiable {
        let id: String
        var value: String
    }
    
    enum ChildAction: Hashable {
        case save(String)
        case saved
    }

    struct ChildEffects {
        let save: any SaveEffect
    }
    
    func testInBounds() async {
        let child = AnonymousReducer<ChildState, ChildAction, ChildEffects> { state, action, effects in
            switch action {
            case let .save(value):
                state.value = value
                
                return SideEffects {
                    effects.save(index: 0, content: value) ~> ChildAction.saved
                }
                
            case .saved:
                state.value = "done"
                return SideEffects.none
            }
        }
        
        let subject = IdentifiableReducer<ParentState, ParentAction, ParentEffects>(
            state: \ParentState.child,
            action: ActionBinding(ParentAction.child),
            effects: \ParentEffects.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: [
            ChildState(id: "one", value: "idle1"),
            ChildState(id: "two", value: "idle2"),
            ChildState(id: "three", value: "idle3")
        ])
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffectHandler(),
                                    save: SaveEffectHandler())
        let sideEffects = subject.reduce(&state, action: .child(.save("thing"), "two"), effects: effects)
        
        
        let expectedState = ParentState(child: [
            ChildState(id: "one", value: "idle1"),
            ChildState(id: "two", value: "thing"),
            ChildState(id: "three", value: "idle3")
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
