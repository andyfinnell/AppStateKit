import Foundation
import Combine
import AppStateKit

struct Account {
    let id: String
    let name: String
}

struct AppComponent: UIComponent {
    struct State: Updatable {
        var accounts: [AccountComponent.State]
        var loadStatus: LoadStatus
    }

    enum Action {
        case account(AccountComponent.Action, String)
        case app(InternalAction)
    }

    enum InternalAction {
        case start
        case loaded([Account])
    }
    
    struct Environment {
        let loadAccounts: () -> AnyPublisher<[Account], Error>
        var accountEnvironment: AccountComponent.Environment {
            AccountComponent.Environment()
        }
    }

    static let reducer = Reducer<State, Action, Environment>.combine(
        AccountComponent.reducer.arrayById(state: \.accounts,
                                           toLocalAction: Action.toAccount,
                                           fromLocalAction: Action.account,
                                           tolocalEnvironment: { $0.accountEnvironment }),
        Self.internalReducer.external(toLocalAction: Action.toInternal,
                                      fromLocalAction: Action.app)
    )
    
    private static let internalReducer = Reducer<State, InternalAction, Environment> { state, action, sideEffect in
        switch action {
        case .start:
            sideEffect { env in
                env.loadAccounts()
                    .map { InternalAction.loaded($0) }
                    .replaceError(with: .loaded([]))
                    .eraseToAnyPublisher()
            }
            return state.update(\.loadStatus, to: .loading)
        case let .loaded(accounts):
            let accountsState = accounts.map {
                AccountComponent.State(id: $0.id,
                                       name: $0.name,
                                       foldersStatus: .idle,
                                       folders: [])
            }
            return state
                .update(\.accounts, to: accountsState)
                .update(\.loadStatus, to: .loaded)
        }
    }
}

private extension AppComponent.Action {
    static func toAccount(_ a: Self) -> (AccountComponent.Action, String)? {
        if case let .account(action, id) = a {
            return (action, id)
        } else {
            return nil
        }
    }
    
    static func toInternal(_ a: Self) -> AppComponent.InternalAction? {
        if case let .app(action) = a {
            return action
        } else {
            return nil
        }
    }
}

extension AppComponent.State: DefaultInitializable {
    init() {
        accounts = []
        loadStatus = .idle
    }
}

extension AppComponent.Environment: DefaultInitializable {
    init() {
        loadAccounts = { Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    }
}
