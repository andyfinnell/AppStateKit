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
        let loadAtIndex: Effect<String, Never, Int>
        let save: Effect<Void, Never, Int, String>
        
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
