import XCTest
import Combine
@testable import AppStateKit

final class AppStateKitTests: XCTestCase {
    func testThings() {
        let env = AppComponent.Environment(mailStore: FakeMailStore())
        let store = AppComponent.makeStore(environment: env)
        
        // TODO: how to make this much more ergonomic?
        let accountId = "frank"
        let accountStore = store.map(toLocalState: { $0.accounts[id: accountId].withFallback() },
                                     fromLocalAction: { .account($0, accountId) })
        let accountViewStore = ViewStore(store: accountStore)
    }
}
