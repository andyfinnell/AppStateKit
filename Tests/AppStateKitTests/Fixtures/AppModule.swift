import Foundation
import Combine
import AppStateKit

struct AppModule: UIModule {
    struct State: Updatable {
        var accounts: [AccountModule.State]
        var loadStatus: LoadStatus
    }

    enum Action {
        case account(AccountModule.Action, String)
        case app(InternalAction)
    }

    enum InternalAction {
        case start
        case loaded([Account])
    }
    
    struct Environment {
        let mailStore: MailStore
    }
    
    enum InternalEffect {
        case loadAccounts
    }
    
    enum Effect {
        case app(InternalEffect)
        case account(AccountModule.Effect, String)
    }
    
    static func performSideEffect(_ effect: InternalEffect, in environment: Environment) -> AnyPublisher<InternalAction, Never> {
        switch effect {
        case .loadAccounts:
            return environment.mailStore.load()
                .map { InternalAction.loaded($0) }
                .replaceError(with: .loaded([]))
                .eraseToAnyPublisher()
        }
    }

    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffect<InternalEffect>) -> State {
        switch action {
        case .start:
            sideEffects(.loadAccounts)
            return state.update(\.loadStatus, to: .loading)
        case let .loaded(accounts):
            let accountsState = accounts.map {
                AccountModule.State(id: $0.id,
                                       name: $0.name,
                                       foldersStatus: .idle,
                                       folders: [])
            }
            return state
                .update(\.accounts, to: accountsState)
                .update(\.loadStatus, to: .loaded)
        }
    }
    
    static let value = UIModuleValue<State, Action, Effect, Environment>.combine(
        AccountModule.value.arrayById(state: \.accounts,
                                           toLocalAction: Action.toAccount,
                                           fromLocalAction: Action.account,
                                           toLocalEffect: Effect.toAccount,
                                           fromLocalEffect: Effect.account,
                                           toLocalEnvironment: { AccountModule.Environment(mailStore: $0.mailStore) }),
        internalValue.external(toLocalAction: Action.toInternal,
                               fromLocalAction: Action.app,
                               toLocalEffect: Effect.toInternal,
                               fromLocalEffect: Effect.app)
    )
}

private extension AppModule.Action {
    static func toAccount(_ a: Self) -> (AccountModule.Action, String)? {
        if case let .account(action, id) = a {
            return (action, id)
        } else {
            return nil
        }
    }
    
    static func toInternal(_ a: Self) -> AppModule.InternalAction? {
        if case let .app(action) = a {
            return action
        } else {
            return nil
        }
    }
}

private extension AppModule.Effect {
    static func toAccount(_ a: Self) -> (AccountModule.Effect, String)? {
        if case let .account(action, id) = a {
            return (action, id)
        } else {
            return nil
        }
    }
    
    static func toInternal(_ a: Self) -> AppModule.InternalEffect? {
        if case let .app(action) = a {
            return action
        } else {
            return nil
        }
    }

}

extension AppModule.State: DefaultInitializable {
    init() {
        accounts = []
        loadStatus = .idle
    }
}
