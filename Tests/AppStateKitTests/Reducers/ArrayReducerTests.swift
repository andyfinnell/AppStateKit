import Foundation
import XCTest
@testable import AppStateKit

final class ArrayReducerTests: XCTestCase {
    struct ParentState: Equatable {
        var child: [ChildState]
    }
    
    enum ParentAction: Extractable, Hashable {
        case child(ChildAction, Int)
    }
        
    struct ParentEffects {
        let loadAtIndex: any LoadAtIndexEffect
        let save: any SaveEffect
        
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
        
        let subject = ArrayReducer<ParentState, ParentAction, ParentEffects>(
            state: \ParentState.child,
            action: ActionBinding(ParentAction.child),
            effects: \ParentEffects.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: [
            ChildState(value: "idle1"),
            ChildState(value: "idle2"),
            ChildState(value: "idle3")
        ])
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffectHandler(),
                                    save: SaveEffectHandler())
        let sideEffects = subject.reduce(&state, action: .child(.save("thing"), 1), effects: effects)
        
        
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
