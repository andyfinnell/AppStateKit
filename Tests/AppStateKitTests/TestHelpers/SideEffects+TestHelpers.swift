import Foundation
import XCTest
@testable import AppStateKit

@MainActor
func testMaterializeEffects<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    let futures = sideEffects.futures
    await withTaskGroup(of: Void.self) { taskGroup in
        for future in futures {
            taskGroup.addTask {
                let action = await future.call()
                await actions.insert(action)
            }
        }
    }
    return await actions.set
}

@MainActor
func testMaterializeSubscriptions<Action: Hashable>(_ sideEffects: SideEffectsContainer<Action>) async -> Set<Action> {
    let actions = AsyncSet<Action>()
    let expectation = XCTestExpectation(description: "subscriptions completion")
    expectation.expectedFulfillmentCount = sideEffects.subscriptions.count
    sideEffects.startSubscriptions(
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
