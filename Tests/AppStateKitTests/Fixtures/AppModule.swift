import Foundation
import Combine
import AppStateKit

struct AppModule: UIModule {
    struct State: Updatable {
        var accounts: [AccountModule.State]
        var loadStatus: LoadStatus
    }

    enum Action: Extractable {
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
    
    enum Effect: Extractable {
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

    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffects<InternalEffect>) -> State {
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
                                      toLocalAction: Action.extractor(Action.account),
                                      fromLocalAction: Action.account,
                                      toLocalEffect: Effect.extractor(Effect.account),
                                      fromLocalEffect: Effect.account,
                                      toLocalEnvironment: { AccountModule.Environment(mailStore: $0.mailStore) }),
        internalValue.external(toLocalAction: Action.extractor(Action.app),
                               fromLocalAction: Action.app,
                               toLocalEffect: Effect.extractor(Effect.app),
                               fromLocalEffect: Effect.app)
    )
}

extension AppModule.State: DefaultInitializable {
    init() {
        accounts = []
        loadStatus = .idle
    }
}
