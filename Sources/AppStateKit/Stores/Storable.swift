import Foundation
import Combine

public protocol Storable: AnyObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    var statePublisher: AnyPublisher<State, Never> { get }
    
    func apply(_ action: Action)
}

public extension Storable {
    func map<LocalState, LocalAction>(toLocalState: @escaping (State) -> LocalState,
                                      fromLocalAction: @escaping (LocalAction) -> Action) -> MapStore<LocalState, LocalAction> {
        MapStore(store: self, toLocalState: toLocalState, fromLocalAction: fromLocalAction)
    }
}
