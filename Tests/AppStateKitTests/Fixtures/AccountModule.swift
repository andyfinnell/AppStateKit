import Foundation
import Combine
import AppStateKit

// TODO: finish fleshing out the various modules down to a message module.
//  Make sure it can model switching between messages, folders, and accounts
struct AccountModule: UIModule {
    struct State: Updatable, Identifiable, Equatable {
        struct Folder: Updatable, Equatable {
            var name: String
            let id: String
            let systemImage: String
        }

        let id: String
        var name: String
        var foldersStatus: LoadStatus
        var folders: [Folder]
    }

    enum Effect {
        case renameFolder(accountId: String, folderId: String, newName: String)
        case loadFolders(accountId: String)
    }
    
    enum Action {
        case renameFolder(folderId: String, newName: String)
        case refreshFolders
        case beginLoading
        case finishedLoading([MailFolder])
        case finishedRename(folder: MailFolder)
        // TODO: create and delete folders as well
    }

    struct Environment {
        let mailStore: MailStore
    }

    static func performSideEffect(_ effect: Effect, in environment: Environment) -> AnyPublisher<Action, Never> {
        switch effect {
        case let .renameFolder(accountId, folderId, newName):
            return environment.mailStore.renameFolder(accountId: accountId,
                                            folderId: folderId,
                                            folderName: newName)
                .catch { _ -> AnyPublisher<MailFolder, Never> in
                    Empty(completeImmediately: true).eraseToAnyPublisher()
                }.map { folder in Action.finishedRename(folder: folder) }
                .eraseToAnyPublisher()
            
        case let .loadFolders(accountId):
            return environment.mailStore.loadFolders(for: accountId)
                .map { Action.finishedLoading($0) }
                .replaceError(with: .finishedLoading([]))
                .prepend(.beginLoading)
                .eraseToAnyPublisher()
        }
    }
    
    static func reduce(_ state: State, action: Action, sideEffects: SideEffect<Effect>) -> State {
        switch action {
        case let .renameFolder(folderId: folderId, newName: newName):
            sideEffects(.renameFolder(accountId: state.id,
                                     folderId: folderId,
                                     newName: newName))
            return state
        case let .finishedRename(folder: folder):
            var updatedFolders = state.folders
            if let updateIndex = state.folders.firstIndex(where: { $0.id == folder.id }) {
                updatedFolders[updateIndex] = state.folders[updateIndex]
                    .update(\.name, to: folder.name)
            }
            return state.update(\.folders, to: updatedFolders)
        case .refreshFolders:
            sideEffects(.loadFolders(accountId: state.id))
            return state
        case .beginLoading:
            return state.update(\.foldersStatus, to: .loading)
        case let .finishedLoading(folders):
            let foldersState = folders.map { State.Folder(name: $0.name, id: $0.id, systemImage: $0.systemImage) }
            return state
                .update(\.folders, to: foldersState)
                .update(\.foldersStatus, to: .loaded)
        }
    }
    
    static var value: UIModuleValue<State, Action, Effect, Environment> {
        internalValue
    }
}

extension AccountModule.State: DefaultInitializable {
    init() {
        id = ""
        name = "<ERROR>"
        foldersStatus = .idle
        folders = []
    }
}
