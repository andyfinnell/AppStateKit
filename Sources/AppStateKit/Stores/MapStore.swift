import Foundation
import Combine
import SwiftUI

public final class MapStore<State, Action> {
    private var cancellables = Set<AnyCancellable>()
    private let applyThunk: (Action) -> Void
    @Published public private(set) var state: State
     
    public init<S: Storable>(store: S,
                             toLocalState: @escaping (S.State) -> State,
                             fromLocalAction: @escaping (Action) -> S.Action) {
        
        state = toLocalState(store.state)
        applyThunk = { [weak store] action in
            store?.apply(fromLocalAction(action))
        }
        store.statePublisher.sink { [weak self] state in
            self?.state = toLocalState(state)
        }.store(in: &cancellables)
    }

    public func apply(_ action: Action) {
        applyThunk(action)
    }
}

extension MapStore: Storable {
    public var statePublisher: AnyPublisher<State, Never> { $state.eraseToAnyPublisher() }
}
