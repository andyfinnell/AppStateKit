import Foundation

@MainActor
public final class DetachedEngine<State, Action: Sendable, Output>: Engine {
    private let isEqual: (State, State) -> Bool
    private let processor: ActionProcessor<State, Action, Output>
    private let _statePublisher = MainPublisher<State>()
    private var stateSink: AnySink? = nil
    private let signalThunk: @MainActor (Output) -> Void
    private let detachedSender = DetachedSender()
    
    public private(set) var state: State
    public var statePublisher: any Publisher<State> { _statePublisher }
    public var internals: Internals { processor.internals }
    
    public init<E: Engine, C: BaseComponent, D: Detachment>(
        engine: E,
        initialState: (E.State) -> State,
        state toLocalState: @escaping (E.State) -> Action?,
        translate: @escaping (C.Output) -> TranslateResult<E.Action, E.Output>,
        dependencies toLocalDependencies: (DependencyScope) -> DependencyScope,
        isEqual: @escaping (State, State) -> Bool,
        component: C.Type,
        detachment: D.Type
    ) where C.State == State, C.Action == Action, C.Output == Output, D.DetachedAction == Action {
        processor = ActionProcessor(
            dependencies: toLocalDependencies(engine.internals.dependencyScope),
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        // Intentionally holding parent in memory
        signalThunk = { @MainActor output in
            switch translate(output) {
            case let .perform(parentAction):
                engine.send(parentAction)
            case let .passThrough(parentOutput):
                engine.signal(parentOutput)
            case .drop: break
            }
        }
        state = initialState(engine.state) // initialize
        self.isEqual = isEqual
        stateSink = engine.statePublisher.sink { [weak self] parentState in
            guard let action = toLocalState(parentState) else {
                return
            }
            Task { @MainActor [weak self] in
                // We call ourown because we're trying to update our state with this
                self?.send(action)
            }
        }
        engine.attach(self, at: detachment)
    }
    
    public func send(_ action: Action) {
        processor.process(
            action,
            on: getState, setState,
            using: { @MainActor [weak self] action in
            self?.send(action)
            }, 
            signalThunk,
            detachedSender: detachedSender
        )
    }
    
    public func signal(_ output: Output) {
        signalThunk(output)
    }
    
    public func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        detachedSender.attach(sender, at: key)
    }
}

private extension DetachedEngine {
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
    public func detach<C: Component, D: Detachment>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        translate: @escaping (C.Output) -> TranslateResult<Action, Output>,
        detachment: D.Type,
        inject: (DependencyScope) -> Void
    ) -> DetachedEngine<C.State, C.Action, C.Output> where D.DetachedAction == C.Action {
        DetachedEngine<C.State, C.Action, C.Output>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: translate,
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { _, _ in false },
            component: component,
            detachment: detachment
        )
    }
    
    public func detach<C: Component, D: Detachment>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        translate: @escaping (C.Output) -> TranslateResult<Action, Output>,
        detachment: D.Type,
        inject: (DependencyScope) -> Void
    ) -> DetachedEngine<C.State, C.Action, C.Output> where C.State: Equatable, D.DetachedAction == C.Action {
        DetachedEngine<C.State, C.Action, C.Output>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: translate,
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { $0 == $1 },
            component: component,
            detachment: detachment
        )
    }

    public func detach<C: Component, D: Detachment>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        detachment: D.Type,
        inject: (DependencyScope) -> Void
    ) -> DetachedEngine<C.State, C.Action, Never> where C.Output == Never, D.DetachedAction == C.Action {
        DetachedEngine<C.State, C.Action, Never>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: { _ -> TranslateResult<Action, Output> in },
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { _, _ in false },
            component: component,
            detachment: detachment
        )
    }
    
    public func detach<C: Component, D: Detachment>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        detachment: D.Type,
        inject: (DependencyScope) -> Void
    ) -> DetachedEngine<C.State, C.Action, Never> where C.State: Equatable, C.Output == Never, D.DetachedAction == C.Action  {
        DetachedEngine<C.State, C.Action, Never>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            translate: { _ -> TranslateResult<Action, Output> in  },
            dependencies: { $0.scoped(inject: inject) },
            isEqual: { $0 == $1 },
            component: component,
            detachment: detachment
        )
    }
}

