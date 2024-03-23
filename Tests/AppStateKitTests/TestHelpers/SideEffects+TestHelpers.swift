import Foundation
import XCTest
@testable import AppStateKit

func testMaterializeEffects<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    await sideEffects.apply(using: { action in
        await actions.insert(action)
    })
    return await actions.set
}

func testMaterializeSubscriptions<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    let expectation = XCTestExpectation(description: "subscriptions completion")
    expectation.expectedFulfillmentCount = sideEffects.subscriptions.count
    await sideEffects.startSubscriptions(
        using: { action in
            await actions.insert(action)
        },
        attachingWith: { task, subscriptionID in
            // nop
        },
        onFinish: { subscriptionID in
            expectation.fulfill()
        })
    _ = await XCTWaiter.fulfillment(of: [expectation], timeout: 1.0)
    return await actions.set

}
