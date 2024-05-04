import Foundation

public final class ScopeEngine<State, Action, Output>: Engine {
    private let isEqual: (State, State) -> Bool
    private let processor: ActionProcessor<State, Action, Output>
    private let _statePublisher = MainPublisher<State>()
    private var stateSink: AnySink? = nil
    private let signalThunk: @MainActor (Output) -> Void
    
    public private(set) var state: State
    public var statePublisher: any Publisher<State> { _statePublisher }
    public var internals: Internals { processor.internals }
    
    public init<E: Engine, C: BaseComponent>(
        engine: E,
        initialState: (E.State) -> State,
        state toLocalState: @escaping (E.State) -> Action?,
        translate: @escaping (C.Output) -> E.Action?,
        dependencies toLocalDependencies: (DependencyScope) -> DependencyScope,
        isEqual: @escaping (State, State) -> Bool,
        component: C.Type
    ) where C.State == State, C.Action == Action, C.Output == Output {
        processor = ActionProcessor(
            dependencies: toLocalDependencies(engine.internals.dependencyScope),
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        // Intentionally holding parent in memory
        signalThunk = { @MainActor output in
            guard let parentAction = translate(output) else {
                return
            }
            engine.send(parentAction)
        }
        state = initialState(engine.state) // initialize
        self.isEqual = isEqual
        stateSink = engine.statePublisher.sink { parentState in
            guard let action = toLocalState(parentState) else {
                return
            }
            Task { @MainActor [weak self] in
                // We call ourown because we're trying to update our state with this
                self?.send(action)
            }
        }
    }
    
    @MainActor
    public func send(_ action: Action) {
        processor.process(
            action,
            on: getState, setState,
            using: { @MainActor [weak self] action in
            self?.send(action)
            }, 
            signalThunk
        )
    }
    
    @MainActor
    public func signal(_ output: Output) {
        signalThunk(output)
    }
}

private extension ScopeEngine {
    func getState() -> State {
        state
    }
    
    func setState(_ state: State) {
        guard !isEqual(self.state, state) else {
            return
        }
        self.state = state
        _statePublisher.didChange(to: state)
    }
}

extension Engine {
    public func scope<C: Component>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        translate: @escaping (C.Output) -> Action?,
        inject: (DependencyScope) -> Void
    ) -> ScopeEngine<C.State, C.Action, C.Output> {
        ScopeEngine<C.State, C.Action, C.Output>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: translate,
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { _, _ in false },
            component: component
        )
    }
    
    public func scope<C: Component>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        translate: @escaping (C.Output) -> Action?,
        inject: (DependencyScope) -> Void
    ) -> ScopeEngine<C.State, C.Action, C.Output> where C.State: Equatable {
        ScopeEngine<C.State, C.Action, C.Output>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: translate,
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { $0 == $1 },
            component: component
        )
    }

    public func scope<C: Component>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        inject: (DependencyScope) -> Void
    ) -> ScopeEngine<C.State, C.Action, Never> where C.Output == Never {
        ScopeEngine<C.State, C.Action, Never>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: { _ in nil },
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { _, _ in false },
            component: component
        )
    }
    
    public func scope<C: Component>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        inject: (DependencyScope) -> Void
    ) -> ScopeEngine<C.State, C.Action, Never> where C.State: Equatable, C.Output == Never  {
        ScopeEngine<C.State, C.Action, Never>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: { _ in nil },
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { $0 == $1 },
            component: component
        )
    }
}

