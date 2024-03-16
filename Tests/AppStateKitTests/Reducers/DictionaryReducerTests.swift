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
                    .saved
                }
                
            case .saved:
                state.value = "done"
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
        let dependencies = DependencyScope()
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                                    save: SaveEffect.makeDefault(with: dependencies))
        let sideEffects = SideEffectsContainer<ParentAction>(dependencyScope: dependencies)
        subject.reduce(
            &state,
            action: .child(.save("thing"), "two"),
            effects: effects,
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
