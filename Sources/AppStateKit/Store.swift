import Foundation
import Combine

public final class Store<State, Action, Effect, Environment> {
    private enum WrappedAction {
        case parentUpdated(State)
        case action(Action)
    }
    private let environment: Environment
    private let actions = PassthroughSubject<WrappedAction, Never>()
    private var cancellables = Set<AnyCancellable>()
    @Published public private(set) var state: State
    
    public init(initialState: State, environment: Environment, component: UIComponentValue<State, Action, Effect, Environment>) {
        self.state = initialState
        self.environment = environment
        
        let applySideEffect = { [weak self] (sideEffect: SideEffect<Effect>) -> Void in
            self?.applySideEffects(sideEffect, using: { component.sideEffectHandler($0, environment) })
        }
        
        let start = Just(initialState).eraseToAnyPublisher()
        actions.scan(start) { state, action in
            switch action {
            case let .action(realAction):
                return Self.handleAction(state: state,
                                         action: realAction,
                                         reducer: component.reducer,
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
                                             fromLocalAction: @escaping (LocalAction) -> Action) -> Store<LocalState, LocalAction, Effect, Environment> {
        let localComponentValue = UIComponentValue<LocalState, LocalAction, Effect, Environment>(reducer: { [weak self] state, action, sideEffect in
                self?.apply(fromLocalAction(action))
                return state
            },
            sideEffectHandler: { _, _ -> AnyPublisher<LocalAction, Never> in
                // this store shouldn't be doing anything.
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            })
        let localStore = Store<LocalState, LocalAction, Effect, Environment>(initialState: toLocalState(state),
                                                                             environment: environment,
                                                                             component: localComponentValue)
        
        // As our state changes, make sure that updates our child's state
        $state.sink(receiveValue: { [weak localStore] state in
            let localState = toLocalState(state)
            localStore?.actions.send(.parentUpdated(localState))
        }).store(in: &localStore.cancellables)
        
        return localStore
    }
}

private extension Store {
    func applySideEffects(_ sideEffect: SideEffect<Effect>, using sideEffectHandler: @escaping (Effect) -> AnyPublisher<Action, Never>) {
        sideEffect.apply(using: sideEffectHandler)
            .map { .action($0) }
            .subscribe(actions)
            .store(in: &cancellables)
    }
    
    static func handleAction(state: AnyPublisher<State, Never>, action: Action, reducer: @escaping (State, Action, SideEffect<Effect>) -> State, applySideEffects: @escaping (SideEffect<Effect>) -> Void) -> AnyPublisher<State, Never> {
        state.map { s  in
            let sideEffect = SideEffect<Effect>()
            let newState = reducer(s, action, sideEffect)
            
            applySideEffects(sideEffect)
            
            return newState
        }.eraseToAnyPublisher()
    }
    
    static func handleParentUpdate(state: AnyPublisher<State, Never>, newState: State) -> AnyPublisher<State, Never> {
        state.map { _ in newState }.eraseToAnyPublisher()
    }
}
