import Foundation
import Combine

struct Account: Equatable {
    let id: String
    let name: String
}

struct Message: Equatable {
    let id: String
    let from: String
    let subject: String
}

struct MailFolderInfo: Equatable {
    let uidNext: Int
    let uidValidity: Int
    let highestModseq: Int
    let exists: Int
}

struct MailFolderSync: Equatable {
    let newMessages: [Message]
    let deletedMessageIds: [String]
    let isReset: Bool // if validity is changed
}

struct MailFolder: Identifiable, Equatable {
    let id: String
    let name: String
    let systemImage: String
}

enum TestError: Error {
    case fail
}

protocol MailStore {
    func load() -> AnyPublisher<[Account], Error>
    func loadFolders(for accountId: String) -> AnyPublisher<[MailFolder], Error>
    func renameFolder(accountId: String, folderId: String, folderName: String) -> AnyPublisher<MailFolder, Error>
    
    func fetchInfo(for accountId: String, folderId: String) -> AnyPublisher<MailFolderInfo, Error>
    func sync(for accountId: String, folderId: String, oldInfo: MailFolderInfo?, newInfo: MailFolderInfo) -> AnyPublisher<MailFolderSync, Error>
}

final class FakeMailStore: MailStore {
    func load() -> AnyPublisher<[Account], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func loadFolders(for accountId: String) -> AnyPublisher<[MailFolder], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func renameFolder(accountId: String, folderId: String, folderName: String) -> AnyPublisher<MailFolder, Error> {
        Just(MailFolder(id: "inbox", name: "Inbox", systemImage: "mail"))
            .setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchInfo(for accountId: String, folderId: String) -> AnyPublisher<MailFolderInfo, Error> {
        Just(MailFolderInfo(uidNext: 1, uidValidity: 1, highestModseq: 1, exists: 1))
            .setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func sync(for accountId: String, folderId: String, oldInfo: MailFolderInfo?, newInfo: MailFolderInfo) -> AnyPublisher<MailFolderSync, Error> {
        Just(MailFolderSync(newMessages: [], deletedMessageIds: [], isReset: false))
            .setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
