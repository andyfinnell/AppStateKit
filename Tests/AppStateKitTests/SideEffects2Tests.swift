import Foundation
import XCTest
import Combine
@testable import AppStateKit

final class SideEffects2Tests: XCTestCase {
    
    struct Effects {
        let loadAtIndex: EffectDecl<Int, String>
        let save: EffectDecl<(index: Int, content: String), Void>
    }
        
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
    }
        
    struct ChildEffects {
        let update: EffectDecl<(index: Int, content: String), String>
    }

    enum ChildAction: Hashable {
        case updated(String)
    }
    
    func testParallelEffects() async {
        let subject = SideEffects2<Effects, Action>(environment: .init(
            loadAtIndex: .init({ (index: Int) async -> String in
                "loaded index \(index)"
            }),
            save: .init({ (index: Int, content: String) async -> Void in
                
            })))
        
        subject.loadAtIndex(4, Action.loaded)
        subject.save((index: 3, content: "my content"), { .saved })
        
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
        let subject = SideEffects2<Effects, Action>(environment: .init(
            loadAtIndex: .init({ (index: Int) async -> String in
                "loaded index \(index)"
            }),
            save: .init({ (index: Int, content: String) async -> Void in
                
            })))
        
        subject.loadAtIndex(4, Action.loaded)
        subject.save((index: 3, content: "my content"), { .saved })

        let childSubject = SideEffects2<ChildEffects, ChildAction>(environment: .init(
            update: .init({ (index: Int, content: String) -> String in
            "update \(content) to \(index)"
        })))
        
        childSubject.update((index: 2, content: "frank"), ChildAction.updated)
        
        subject.append(childSubject, using: Action.child)
        
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
