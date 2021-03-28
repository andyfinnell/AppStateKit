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
        
        var selectedFolder: MailFolderModule.State?
    }

    enum Effect: Extractable {
        case account(InternalEffect)
        case folder(MailFolderModule.Effect)
    }
    
    enum InternalEffect {
        case renameFolder(accountId: String, folderId: String, newName: String)
        case loadFolders(accountId: String)
        case startSync(folderId: String)
    }
    
    enum Action: Extractable {
        case account(InternalAction)
        case folder(MailFolderModule.Action)
        
        static func reroute(_ internalAction: InternalAction) -> Action {
            switch internalAction {
            case .startSync:
                return Action.folder(.startSync)
            default:
                return Action.account(internalAction)
            }
        }
    }
    
    enum InternalAction {
        case renameFolder(folderId: String, newName: String)
        case refreshFolders
        case beginLoading
        case finishedLoading([MailFolder])
        case finishedRename(folder: MailFolder)
        case select(folderId: String)
        case startSync(folderId: String)
        // TODO: create and delete folders as well
    }

    struct Environment {
        let mailStore: MailStore
    }

    static func performSideEffect(_ effect: InternalEffect, in environment: Environment) -> AnyPublisher<InternalAction, Never> {
        switch effect {
        case let .renameFolder(accountId, folderId, newName):
            return environment.mailStore.renameFolder(accountId: accountId,
                                            folderId: folderId,
                                            folderName: newName)
                .catch { _ -> AnyPublisher<MailFolder, Never> in
                    Empty(completeImmediately: true).eraseToAnyPublisher()
                }.map { folder in InternalAction.finishedRename(folder: folder) }
                .eraseToAnyPublisher()
            
        case let .loadFolders(accountId):
            return environment.mailStore.loadFolders(for: accountId)
                .map { InternalAction.finishedLoading($0) }
                .replaceError(with: .finishedLoading([]))
                .prepend(.beginLoading)
                .eraseToAnyPublisher()
            
        case let .startSync(folderId: folderId):
            return Just(.startSync(folderId: folderId)).eraseToAnyPublisher()
        }
    }
    
    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffects<InternalEffect>) -> State {
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
        case let .select(folderId: folderId):
            guard let folder = state.folders.first(where: { $0.id == folderId }) else {
                return state
            }
            
            let folderState = MailFolderModule.State(name: folder.name,
                                                     id: folder.id,
                                                     accountId: state.id,
                                                     systemImage: folder.systemImage,
                                                     loadedMessages: [],
                                                     info: nil,
                                                     infoStatus: .idle)
            
            sideEffects(.startSync(folderId: folderId))
            
            return state.update(\.selectedFolder, to: folderState)
        case .startSync:
            return state // nop, because gets re-routed
        }
    }
    
    static let value = UIModuleValue<State, Action, Effect, Environment>.combine(
        MailFolderModule.value.optional().property(state: \.selectedFolder,
                                                   toLocalAction: Action.extractor(Action.folder),
                                                   fromLocalAction: Action.folder,
                                                   toLocalEffect: Effect.extractor(Effect.folder),
                                                   fromLocalEffect: Effect.folder,
                                                   toLocalEnvironment: { MailFolderModule.Environment(mailStore: $0.mailStore) }),
        internalValue.external(toLocalAction: Action.extractor(Action.account),
                               fromLocalAction: Action.reroute,
                               toLocalEffect: Effect.extractor(Effect.account),
                               fromLocalEffect: Effect.account)
    )
}

extension AccountModule.State: DefaultInitializable {
    init() {
        id = ""
        name = "<ERROR>"
        foldersStatus = .idle
        folders = []
    }
}
