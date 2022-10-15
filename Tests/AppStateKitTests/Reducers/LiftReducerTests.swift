import Foundation
import XCTest
@testable import AppStateKit

final class LiftReducerTests: XCTestCase {
    enum ParentAction: Extractable, Hashable {
        case child(ChildAction)
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
    
    func testLift() async {
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
        
        let subject = LiftReducer(action: ActionBinding(ParentAction.child),
                                  effects: \ParentEffects.child) {
            child
        }
        
        
        // Verify the reducer
        var state = ChildState(value: "idle")
        let effects = ParentEffects(loadAtIndex: LoadAtIndexEffectHandler(),
                                    save: SaveEffectHandler())
        let sideEffects = subject.reduce(&state, action: .child(.save("thing")), effects: effects)
        
        
        XCTAssertEqual(state, ChildState(value: "thing"))
        
        // Verify the effects
        let actualActions = await testMaterializeEffects(sideEffects)
        let expectedActions = Set<ParentAction>([
            .child(.saved)
        ])
        XCTAssertEqual(actualActions, expectedActions)
    }

}
