import Foundation
import XCTest
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
    
    struct Effects {
        let loadAtIndex: Effect<String, Never, Int>
        let save: Effect<Void, Never, Int, String>
    }
        
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
    }
        
    struct ChildEffects {
        let update: Effect<String, Never, Int, String>
    }

    enum ChildAction: Hashable {
        case updated(String)
    }
    
    func testParallelEffects() async {
        let dependencies = DependencySpace()
        let effects = Effects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                              save: SaveEffect.makeDefault(with: dependencies))
        let subject = SideEffects<Action>()
        
        subject.perform(effects.loadAtIndex, with: 4) {
            .loaded($0)
        }
        subject.perform(effects.save, with: 3, "my content") {
            .saved
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
        let dependencies = DependencySpace()
        let effects = Effects(loadAtIndex: LoadAtIndexEffect.makeDefault(with: dependencies),
                              save: SaveEffect.makeDefault(with: dependencies))
        let subject = SideEffects<Action>()
        
        subject.perform(effects.loadAtIndex, with: 4) {
            .loaded($0)
        }
        subject.perform(effects.save, with: 3, "my content") {
            .saved
        }

        let childEffects = ChildEffects(update: UpdateEffect.makeDefault(with: dependencies))

        let childSubject = SideEffects<ChildAction>()
        
        childSubject.perform(childEffects.update, with: 2, "frank") {
            .updated($0)
        }
        
        subject.appending(childSubject, using: Action.child)
        
        let actions = AsyncSet<Action>()
        await subject.apply(using: {
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
