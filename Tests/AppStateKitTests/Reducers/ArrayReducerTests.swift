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
    
    func testInBounds() async {
        let child = AnonymousReducer<ChildState, ChildAction, ChildEffects> { state, action, effects, sideEffects in
            switch action {
            case let .save(value):
                state.value = value
                
                sideEffects.perform(effects.save, with: 0, value) {
                    ChildAction.saved
                }
                
            case .saved:
                state.value = "done"
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
        let dependencies = DependencySpace()
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                                    save: SaveEffect.makeDefault(with: dependencies))
        let sideEffects = SideEffects<ParentAction>()
        subject.reduce(
            &state,
            action: .child(.save("thing"), 1),
            effects: effects,
            sideEffects: sideEffects
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
