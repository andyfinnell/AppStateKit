import XCTest
import Combine
@testable import AppStateKit

final class AppStateKitTests: XCTestCase {
    func testThings() {
        let env = AppModule.Environment(mailStore: FakeMailStore())
        let store = AppModule.makeStore(environment: env)
        
        let accountId = "frank"
        let accountStore = store.map(toLocalState: { $0.accounts[id: accountId].withFallback() },
                                     fromLocalAction: { .account($0, accountId) })
        let accountViewStore = ViewStore(store: accountStore)
    }
}
