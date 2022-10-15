import Foundation
import XCTest
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
    
    struct Effects {
        let loadAtIndex: any LoadAtIndexEffect
        let save: any SaveEffect
    }
        
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
    }
        
    struct ChildEffects {
        let update: any UpdateEffect
    }

    enum ChildAction: Hashable {
        case updated(String)
    }
    
    func testParallelEffects() async {
        let effects = Effects(loadAtIndex: LoadAtIndexEffectHandler(),
                              save: SaveEffectHandler())
        
        let subject = SideEffects {
            effects.loadAtIndex(index: 4) ~> Action.loaded
            
            effects.save(index: 3, content: "my content") ~> Action.saved
        }
        
        let actions = AsyncSet<Action>()
        await subject.apply(using: {
            await actions.insert($0)
        })
        
        let expected = Set<Action>([
            .loaded("loaded index 4"),
            .saved
        ])
        let actual = await actions.set
        XCTAssertEqual(actual, expected)
    }
    
    func testCombinedEffects() async {
        let effects = Effects(loadAtIndex: LoadAtIndexEffectHandler(),
                              save: SaveEffectHandler())
        
        let subject = SideEffects {
            effects.loadAtIndex(index: 4) ~> Action.loaded
            
            effects.save(index: 3, content: "my content") ~> Action.saved
        }


        let childEffects = ChildEffects(update: UpdateEffectHandler())

        let childSubject = SideEffects {
            childEffects.update(index: 2, content: "frank") ~> ChildAction.updated
        }
        
        let results = subject.appending(childSubject, using: Action.child)
        
        let actions = AsyncSet<Action>()
        await results.apply(using: {
            await actions.insert($0)
        })

        let expected = Set<Action>([
            .loaded("loaded index 4"),
            .saved,
            .child(.updated("update frank to 2"))
        ])
        let actual = await actions.set
        XCTAssertEqual(actual, expected)
    }
}
