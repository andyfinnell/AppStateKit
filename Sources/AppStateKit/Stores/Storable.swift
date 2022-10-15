import Foundation
import Combine

public protocol Storable: AnyObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    var statePublisher: AnyPublisher<State, Never> { get }
    
    func apply(_ action: Action) async
}

public extension Storable {
    func apply(_ action: Action) {
        Task {
            await apply(action)
        }
    }
}
