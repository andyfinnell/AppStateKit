import Foundation
import XCTest
@testable import AppStateKit

final class LiftReducerTests: XCTestCase {
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
    
    func testLift() async {
        let child = AnonymousReducer<ChildState, ChildAction, ChildEffects> { state, action, effects, sideEffects in
            switch action {
            case let .save(value):
                state.value = value
                
                sideEffects.perform(effects.save, with: 0, value) { _ in
                    ChildAction.saved
                }
                
            case .saved:
                state.value = "done"
            }
        }
        
        let subject = LiftReducer(action: ActionBinding(ParentAction.child),
                                  effects: \ParentEffects.child) {
            child
        }
        
        
        // Verify the reducer
        var state = ChildState(value: "idle")
        let dependencies = DependencySpace()
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                                    save: SaveEffect.makeDefault(with: dependencies))
        let sideEffects = SideEffects<ParentAction>()
        subject.reduce(
            &state,
            action: ParentAction.child(.save("thing")),
            effects: effects,
            sideEffects: sideEffects
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
