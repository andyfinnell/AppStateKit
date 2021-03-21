import Foundation
import Combine
import AppStateKit

struct MailFolderComponent: UIComponent {
    struct State: Updatable {
        struct Message: Updatable {
            let id: String
            let from: String
            let subject: String
        }
        struct Info: Equatable {
            var uidNext: Int
            var uidValidity: Int
            var highestModseq: Int
            var exists: Int
        }
        var name: String
        let id: String
        let systemImage: String
        var loadedMessages: [Message]
        var info: Info?
        var infoStatus: LoadStatus
    }

    enum Action {
        case startSync
        case processSync(MailFolderSync)
        case updateInfo(State.Info)
        case infoUpdateFailed
    }

    struct MailFolderSync {
        let newMessages: [State.Message]
        let deletedMessageIds: [String]
        let isReset: Bool // if validity is changed
    }

    struct Environment {
        let fetchInfo: (String) -> AnyPublisher<State.Info, Error>
        let sync: (String, State.Info?, State.Info) -> AnyPublisher<MailFolderSync, Error>
    }

    static let reducer = Reducer<State, Action, Environment>() { state, action, sideEffect in
        switch action {
        case .startSync:
            // If we're already in a sync, bail
            if state.infoStatus == .loading {
                return state
            }
            
            sideEffect { env in
                env.fetchInfo(state.id)
                    .map { Action.updateInfo($0) }
                    .replaceError(with: .infoUpdateFailed)
                    .eraseToAnyPublisher()
            }
            
            return state.update(\.infoStatus, to: .loading)
        case .infoUpdateFailed:
            return state.update(\.infoStatus, to: .idle)
        case let .updateInfo(newInfo):
            sideEffect { env in
                env.sync(state.id, state.info, newInfo)
                    .map { Action.processSync($0) }
                    .catch { _ in Empty(completeImmediately: true).eraseToAnyPublisher() }
                    .eraseToAnyPublisher()
            }
            
            return state
                .update(\.infoStatus, to: .loaded)
                .update(\.info, to: newInfo)
        case let .processSync(sync):
            let messages: [State.Message]
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
}
