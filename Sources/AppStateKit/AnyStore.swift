import Foundation
import Combine

public final class AnyStore<State, Action>: Storable {
    private let stateThunk: () -> State
    private let statePublisherThunk: () -> AnyPublisher<State, Never>
    private let applyThunk: (Action) -> Void
    
    public init<S: Storable>(_ store: S) where S.Action == Action, S.State == State {
        stateThunk = { store.state }
        statePublisherThunk = { store.statePublisher }
        applyThunk = { action in
            store.apply(action)
        }
    }
    
    public var state: State { stateThunk() }
    public var statePublisher: AnyPublisher<State, Never> { statePublisherThunk() }
    
    public func apply(_ action: Action) {
        applyThunk(action)
    }
}

public extension Storable {
    func eraseToAnyStore() -> AnyStore<State, Action> {
        AnyStore(self)
    }
}
