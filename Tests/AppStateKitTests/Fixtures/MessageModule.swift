import Foundation
import Combine
import AppStateKit

struct MessageModule: UIModule {
    struct State: Updatable, Equatable {
        let accountId: String
        let folderId: String
        let messageId: String
        let from: String
        let subject: String
        var fullText: String
        var loadStatus: LoadStatus
    }
    
    enum Action {
        // TODO: if we delete a message, where does that go, how does that work?
        case load
        case loadFailed
        case loaded(String)
    }
    
    enum Effect {
        case loadMessage(accountId: String, folderId: String, messageId: String)
    }
    
    struct Environment {
        let mailStore: MailStore
    }
    
    static func performSideEffect(_ effect: Effect, in environment: Environment) -> AnyPublisher<Action, Never> {
        switch effect {
        case let .loadMessage(accountId: accountId, folderId: folderId, messageId: messageId):
            return environment.mailStore.loadMessage(for: accountId,
                                                     folderId: folderId,
                                                     messageId: messageId)
                .map { Action.loaded($0) }
                .replaceError(with: .loadFailed)
                .eraseToAnyPublisher()
        }
    }
    
    static func reduce(_ state: State, action: Action, sideEffects: SideEffects<Effect>) -> State {
        switch action {
        case .load:
            sideEffects(.loadMessage(accountId: state.accountId,
                                     folderId: state.folderId,
                                     messageId: state.messageId))
            return state.update(\.loadStatus, to: .loading)
            
        case .loadFailed:
            return state.update(\.loadStatus, to: .idle)
            
        case let .loaded(message):
            return state.update(\.fullText, to: message)
                .update(\.loadStatus, to: .loaded)
        }
    }
    
    static var value: UIModuleValue<State, Action, Effect, Environment> { internalValue }
}
