import Foundation
import Combine
import AppStateKit

struct MailFolderModule: UIModule {
    struct State: Updatable, Equatable {
        var name: String
        let id: String
        let accountId: String
        let systemImage: String
        var loadedMessages: [Message]
        var info: MailFolderInfo?
        var infoStatus: LoadStatus
        
        var selectedMessage: MessageModule.State?
    }

    enum Action: Extractable {
        case folder(InternalAction)
        case message(MessageModule.Action)
        
        static func reroute(_ internalAction: InternalAction) -> Action {
            switch internalAction {
            case .messageLoad:
                return Action.message(.load)
            default:
                return Action.folder(internalAction)
            }
        }

    }
    
    enum InternalAction {
        case startSync
        case processSync(MailFolderSync)
        case updateInfo(MailFolderInfo)
        case infoUpdateFailed
        case selectMessage(messageId: String)
        case messageLoad
    }

    struct Environment {
        let mailStore: MailStore
    }

    enum Effect: Extractable {
        case folder(InternalEffect)
        case message(MessageModule.Effect)
    }
    
    enum InternalEffect {
        case fetchInfo(accountId: String, folderId: String)
        case sync(accountId: String, folderId: String, oldInfo: MailFolderInfo?, newInfo: MailFolderInfo)
        case loadMessage
    }
    
    static func performSideEffect(_ effect: InternalEffect, in environment: Environment) -> AnyPublisher<InternalAction, Never> {
        switch effect {
        case let .fetchInfo(accountId, folderId):
            return environment.mailStore.fetchInfo(for: accountId, folderId: folderId)
                .map { InternalAction.updateInfo($0) }
                .replaceError(with: .infoUpdateFailed)
                .eraseToAnyPublisher()

        case let .sync(accountId, folderId, oldInfo, newInfo):
            return environment.mailStore.sync(for: accountId, folderId: folderId, oldInfo: oldInfo, newInfo: newInfo)
                .map { InternalAction.processSync($0) }
                .catch { _ in Empty(completeImmediately: true).eraseToAnyPublisher() }
                .eraseToAnyPublisher()
            
        case .loadMessage:
            return Just(.messageLoad).eraseToAnyPublisher()
        }

    }
    
    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffects<InternalEffect>) -> State {
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
            }
            return state.update(\.loadedMessages, to: messages)
            
        case let .selectMessage(messageId: messageId):
            guard let message = state.loadedMessages.first(where: { $0.id == messageId }) else {
                return state
            }
            
            let messageState = MessageModule.State(accountId: state.accountId,
                                                   folderId: state.id,
                                                   messageId: messageId,
                                                   from: message.from,
                                                   subject: message.subject,
                                                   fullText: "",
                                                   loadStatus: .idle)
            
            sideEffects(.loadMessage)
            
            return state.update(\.selectedMessage, to: messageState)

        case .messageLoad:
            return state // nop, gets re-routed
        }
    }
    
    static let value = UIModuleValue<State, Action, Effect, Environment>.combine(
        MessageModule.value.optional().property(state: \.selectedMessage,
                                                   toLocalAction: Action.extractor(Action.message),
                                                   fromLocalAction: Action.message,
                                                   toLocalEffect: Effect.extractor(Effect.message),
                                                   fromLocalEffect: Effect.message,
                                                   toLocalEnvironment: { MessageModule.Environment(mailStore: $0.mailStore) }),
        internalValue.external(toLocalAction: Action.extractor(Action.folder),
                               fromLocalAction: Action.reroute,
                               toLocalEffect: Effect.extractor(Effect.folder),
                               fromLocalEffect: Effect.folder)
    )
}
