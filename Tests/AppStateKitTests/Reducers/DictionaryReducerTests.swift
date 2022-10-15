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
                return SideEffects.none()
            }
        }
        
        let subject = DictionaryReducer<ParentState, ParentAction, ParentEffects>(
            state: \ParentState.child,
            action: ActionBinding(ParentAction.child),
            effects: \ParentEffects.child) {
                child
            }
        
        
        // Verify the reducer
        var state = ParentState(child: [
            "one": ChildState(value: "idle1"),
            "two": ChildState(value: "idle2"),
            "three": ChildState(value: "idle3")
        ])
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffectHandler(),
                                    save: SaveEffectHandler())
        let sideEffects = subject.reduce(&state, action: .child(.save("thing"), "two"), effects: effects)
        
        
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
