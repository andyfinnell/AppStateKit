import Foundation
import Combine

public final class Store<State, Action, Environment> {
    private enum WrappedAction {
        case parentUpdated(State)
        case action(Action)
    }
    private let actions = PassthroughSubject<WrappedAction, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let environment: Environment
    @Published public private(set) var state: State
    
    public init(initialState: State, reducer: Reducer<State, Action, Environment>, environment: Environment) {
        self.state = initialState
        self.environment = environment
        
        let applySideEffect = { [weak self] (sideEffect: SideEffect<Environment, Action>) -> Void in
            self?.applySideEffects(sideEffect)
        }
        
        let start = Just(initialState).eraseToAnyPublisher()
        actions.scan(start) { state, action in
            switch action {
            case let .action(realAction):
                return Self.handleAction(state: state,
                                         action: realAction,
                                         reducer: reducer,
                                         applySideEffects: applySideEffect)
            case let .parentUpdated(newState):
                return Self.handleParentUpdate(state: state, newState: newState)
            }
        }.flatMap { $0 }
        .sink { [weak self] value in
            self?.state = value
        }.store(in: &cancellables)
    }
 
    public func apply(_ action: Action) {
        actions.send(.action(action))
    }
        
    public func map<LocalState, LocalAction>(toLocalState: @escaping (State) -> LocalState,
                                               fromLocalAction: @escaping (LocalAction) -> Action) -> Store<LocalState, LocalAction, Environment> {
        let localReducer = Reducer<LocalState, LocalAction, Environment> { [weak self] state, action, sideEffect in
            self?.apply(fromLocalAction(action))
            return state
        }
        let localStore = Store<LocalState, LocalAction, Environment>(initialState: toLocalState(state),
                                                                     reducer: localReducer,
                                                                     environment: environment)
        
        // As our state changes, make sure that updates our child's state
        $state.sink(receiveValue: { [weak localStore] state in
            let localState = toLocalState(state)
            localStore?.actions.send(.parentUpdated(localState))
        }).store(in: &localStore.cancellables)
        
        return localStore
    }
}

private extension Store {
    func applySideEffects(_ sideEffect: SideEffect<Environment, Action>) {
        sideEffect.apply(in: environment)
            .map { .action($0) }
            .subscribe(actions)
            .store(in: &cancellables)
    }
    
    static func handleAction(state: AnyPublisher<State, Never>, action: Action, reducer: Reducer<State, Action, Environment>, applySideEffects: @escaping (SideEffect<Environment, Action>) -> Void) -> AnyPublisher<State, Never> {
        state.map { s  in
            let sideEffect = SideEffect<Environment, Action>()
            let newState = reducer(state: s, action: action, sideEffect: sideEffect)
            
            applySideEffects(sideEffect)
            
            return newState
        }.eraseToAnyPublisher()
    }
    
    static func handleParentUpdate(state: AnyPublisher<State, Never>, newState: State) -> AnyPublisher<State, Never> {
        state.map { _ in newState }.eraseToAnyPublisher()
    }
}
