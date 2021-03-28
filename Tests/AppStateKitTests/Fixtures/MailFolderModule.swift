import Foundation
import Combine
import AppStateKit

struct MailFolderModule: UIModule {
    struct State: Updatable {
        var name: String
        let id: String
        let accountId: String
        let systemImage: String
        var loadedMessages: [Message]
        var info: MailFolderInfo?
        var infoStatus: LoadStatus
    }

    enum Action {
        case startSync
        case processSync(MailFolderSync)
        case updateInfo(MailFolderInfo)
        case infoUpdateFailed
    }

    struct Environment {
        let mailStore: MailStore
    }

    enum Effect {
        case fetchInfo(accountId: String, folderId: String)
        case sync(accountId: String, folderId: String, oldInfo: MailFolderInfo?, newInfo: MailFolderInfo)
    }
    
    static func performSideEffect(_ effect: Effect, in environment: Environment) -> AnyPublisher<Action, Never> {
        switch effect {
        case let .fetchInfo(accountId, folderId):
            return environment.mailStore.fetchInfo(for: accountId, folderId: folderId)
                .map { Action.updateInfo($0) }
                .replaceError(with: .infoUpdateFailed)
                .eraseToAnyPublisher()

        case let .sync(accountId, folderId, oldInfo, newInfo):
            return environment.mailStore.sync(for: accountId, folderId: folderId, oldInfo: oldInfo, newInfo: newInfo)
                .map { Action.processSync($0) }
                .catch { _ in Empty(completeImmediately: true).eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }

    }
    
    static func reduce(_ state: State, action: Action, sideEffects: SideEffect<Effect>) -> State {
        switch action {
        case .startSync:
            // If we're already in a sync, bail
            if state.infoStatus == .loading {
                return state
            }
            
            sideEffects(.fetchInfo(accountId: state.accountId, folderId: state.id))
            
            return state.update(\.infoStatus, to: .loading)
        case .infoUpdateFailed:
            return state.update(\.infoStatus, to: .idle)
        case let .updateInfo(newInfo):
            sideEffects(.sync(accountId: state.accountId, folderId: state.id, oldInfo: state.info, newInfo: newInfo))
            
            return state
                .update(\.infoStatus, to: .loaded)
                .update(\.info, to: newInfo)
        case let .processSync(sync):
            let messages: [Message]
            if sync.isReset {
                messages = sync.newMessages
            } else {
                let deletedIds = Set(sync.deletedMessageIds)
                messages = sync.newMessages
                    + state.loadedMessages.filter { !deletedIds.contains($0.id) }
                // TODO: sort by date?

            }
            return state.update(\.loadedMessages, to: messages)
        }
    }
    
    static var value: UIModuleValue<State, Action, Effect, Environment> { internalValue }
}
