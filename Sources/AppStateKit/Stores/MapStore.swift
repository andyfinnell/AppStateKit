import Foundation
import Combine

public final class MapStore<State, Action> {
    private var cancellables = Set<AnyCancellable>()
    private let applyThunk: (Action) async -> Void
    @PublishedState public private(set) var state: State
    
    public init<S: Storable>(
        store: S,
        state toLocalState: @escaping (S.State) -> State,
        action fromLocalAction: @escaping (Action) -> S.Action
    ) {
        
        state = toLocalState(store.state)
        // Intentionally holding parent in memory
        applyThunk = { action in
            await store.apply(fromLocalAction(action))
        }
        store.statePublisher.sink { [weak self] state in
            self?.state = toLocalState(state)
        }.store(in: &cancellables)
    }
    
    public func apply(_ action: Action) async {
        await applyThunk(action)
    }
}

extension MapStore: Storable {
    public var statePublisher: AnyPublisher<State, Never> { $state }
}

public extension Storable {
    func map<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> MapStore<LocalState, LocalAction> {
        MapStore(store: self, state: toLocalState, action: fromLocalAction)
    }
}
