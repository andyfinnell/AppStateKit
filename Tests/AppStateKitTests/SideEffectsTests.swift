import Foundation
import XCTest
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
            
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
    }
        
    enum ChildAction: Hashable {
        case updated(String)
    }
    
    func testParallelEffects() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let sideEffects = subject.eraseToAnySideEffects()
        
        sideEffects.perform(\.loadAtIndex, with: 4) {
            .loaded($0)
        }
        sideEffects.perform(\.save, with: 3, "my content") {
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
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        
        let sideEffects = subject.eraseToAnySideEffects()
        sideEffects.perform(\.loadAtIndex, with: 4) {
            .loaded($0)
        }
        sideEffects.perform(\.save, with: 3, "my content") {
            .saved
        }

        let childSubject = sideEffects.map { Action.child($0) }
        
        childSubject.perform(\.update, with: 2, "frank") {
            .updated($0)
        }
                
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
