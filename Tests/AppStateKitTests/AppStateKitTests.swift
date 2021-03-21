import XCTest
import Combine
@testable import AppStateKit

struct MailFolder: Identifiable {
    let id: String
    let name: String
    let systemImage: String
}

enum TestError: Error {
    case fail
}

/*
func makeAccountStore() -> Store<AccountState, AccountAction, AccountEnvironment> {
    
    let accountEnvironment = AccountEnvironment(loadFolders: { _ in Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() },
                                         renameFolder: { _, _, _ in Fail(error: TestError.fail).eraseToAnyPublisher() })
    let accountInitialState = AccountState(id: "default", name: "Default", foldersStatus: .idle, folders: [])
    let accountStore = Store<AccountState, AccountAction, AccountEnvironment>(initialState: accountInitialState,
                                                                              reducer: accountReducer,
                                                                              environment: accountEnvironment)
    accountStore.apply(.refreshFolders)
    
    return accountStore
}


func makeMailFolderStore(for folderId: String, from accountStore: Store<AccountState, AccountAction, AccountEnvironment>) -> Store<MailFolderState, MailFolderAction, MailFolderEnvironment> {
    let environment = MailFolderEnvironment(
        fetchInfo: { _ in
            Just(MailFolderState.Info(uidNext: 0, uidValidity: 0, highestModseq: 0, exists: 1))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }, sync: { _, _, _ in
            Just(MailFolderSync(newMessages: [], deletedMessageIds: [], isReset: true))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        })
    let toMailFolderState = { (accountState: AccountState) -> MailFolderState in
        // TODO: implement this. Handle renames, at least
        guard let folderInfo = accountState.folders.first(where: { $0.id == folderId }) else {
            return MailFolderState(name: "<deleted>",
                                   id: folderId,
                                   systemImage: "inbox",
                                   loadedMessages: [],
                                   info: nil,
                                   infoStatus: .idle)

        }
        // TODO: I don't want to overwrite certain fields
        return MailFolderState(name: folderInfo.name,
                               id: folderId,
                               systemImage: folderInfo.systemImage,
                               loadedMessages: <#T##[MailFolderState.Message]#>,
                               info: <#T##MailFolderState.Info?#>,
                               infoStatus: <#T##LoadStatus#>)
    }
    
    let fromMailFolderAction = { (action: MailFolderAction) -> AccountAction? in
        return nil // currently no actions so propagate up
    }
    

    return accountStore.scope(toLocalState: toMailFolderState,
                              toToLocalEnvironment: { _ in environment },
                              fromLocalAction: fromMailFolderAction,
                              reducer: reducer)
}


struct MessageState {
    let id: String
    let from: String
    let subject: String
    // TODO: do we want full text here yet?
    let fullText: String
}
*/

final class AppStateKitTests: XCTestCase {
    func testThings() {
        // TODO: standing up an environment still isn't fleshed out
        let store = AppComponent.makeStore()
        
        // TODO: how to make this much more ergonomic?
        let accountId = "frank"
        let accountStore = store.map(toLocalState: { $0.accounts[id: accountId].withFallback() },
                                     fromLocalAction: { .account($0, accountId) })
        let accountViewStore = ViewStore(store: accountStore)
    }
}
