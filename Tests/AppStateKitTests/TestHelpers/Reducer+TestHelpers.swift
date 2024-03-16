import Foundation
@testable import AppStateKit

func testMaterializeEffects<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    await sideEffects.apply(using: {
        await actions.insert($0)
    })
    
    return await actions.set
}
