import Foundation
@testable import AppStateKit

func testMaterializeEffects<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    await sideEffects.apply(using: { action in
        await actions.insert(action)
    })
    return await actions.set
}
