import Foundation
import Combine
import AppStateKit

struct AccountComponent: UIComponent {    
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

    enum Action {
        case renameFolder(folderId: String, newName: String)
        case refreshFolders
        case beginLoading
        case finishedLoading([MailFolder])
        case finishedRename(folder: MailFolder)
        // TODO: create and delete folders as well
    }

    struct Environment {
        let loadFolders: (String) -> AnyPublisher<[MailFolder], Error>
        let renameFolder: (String, String, String) -> AnyPublisher<MailFolder, Error>
    }

    static let reducer = Reducer<State, Action, Environment> { state, action, sideEffect in
        switch action {
        case let .renameFolder(folderId: folderId, newName: newName):
            sideEffect { env in
                env.renameFolder(state.id, folderId, newName)
                    .catch { _ in
                        Empty(completeImmediately: true).eraseToAnyPublisher()
                    }.map { folder in Action.finishedRename(folder: folder) }
                    .eraseToAnyPublisher()
            }
            return state
        case let .finishedRename(folder: folder):
            var updatedFolders = state.folders
            if let updateIndex = state.folders.firstIndex(where: { $0.id == folder.id }) {
                updatedFolders[updateIndex] = state.folders[updateIndex]
                    .update(\.name, to: folder.name)
            }
            return state.update(\.folders, to: updatedFolders)
        case .refreshFolders:
            sideEffect { env in
                env.loadFolders(state.id)
                    .map { Action.finishedLoading($0) }
                    .replaceError(with: .finishedLoading([]))
                    .prepend(.beginLoading)
                    .eraseToAnyPublisher()
            }
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
}

extension AccountComponent.State: DefaultInitializable {
    init() {
        id = ""
        name = "<ERROR>"
        foldersStatus = .idle
        folders = []
    }
}

extension AccountComponent.Environment: DefaultInitializable {
    init() {
        loadFolders = { _ in Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
        renameFolder = { _, _, _ in Fail(error: TestError.fail).eraseToAnyPublisher() }
    }
}
