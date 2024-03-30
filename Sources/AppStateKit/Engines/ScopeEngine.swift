import Foundation
import Observation

@Observable
public final class ScopeEngine<State, Action>: Engine {
    private let processor: ActionProcessor<State, Action>
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> Action?
    
    public private(set) var state: State
    public var internals: Internals { processor.internals }
    
    public init<E: Engine, C: BaseComponent>(
        engine: E,
        initialState: (E.State) -> State,
        state toLocalState: @escaping (E.State) -> Action?,
        action fromLocalAction: @escaping (Action) -> E.Action?,
        dependencies toLocalDependencies: (DependencyScope) -> DependencyScope,
        component: C.Type
    ) where C.State == State, C.Action == Action {
        processor = ActionProcessor(
            dependencies: toLocalDependencies(engine.internals.dependencyScope),
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            guard let parentAction = fromLocalAction(action) else {
                return
            }
            engine.send(parentAction)
        }
        stateThunk = {
            toLocalState(engine.state)
        }
        state = initialState(engine.state) // initialize
        
        stateDidChange()
    }
    
    @MainActor
    public func send(_ action: Action) {
        sendThunk(action)
        processor.process(action, on: &state, using: { @MainActor [weak self] action in
            self?.send(action)
        })
    }
}

private extension ScopeEngine {
    func stateDidChange() {
        startObserving(stateThunk, onChange: { action in
            guard let action else {
                return
            }
            Task { @MainActor [weak self] in
                self?.send(action)
            }
        })
    }
}

extension Engine {
    public func scope<C: Component>(
        component: C.Type,
        initialState: (State) -> C.State,
        actionToUpdateState: @escaping (State) -> C.Action?,
        actionToPassUp: @escaping (C.Action) -> Action?,
        inject: (DependencyScope) -> Void
    ) -> ScopeEngine<C.State, C.Action> {
        ScopeEngine<C.State, C.Action>(
            engine: self,
            initialState: initialState,
            state: actionToUpdateState,
            action: actionToPassUp,
            dependencies: { $0.scoped(inject: inject) },
            component: component
        )
    }
}
