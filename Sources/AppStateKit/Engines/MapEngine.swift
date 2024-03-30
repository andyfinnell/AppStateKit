import Foundation
import Observation

@Observable
public final class MapEngine<State, Action>: Engine {
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> State
    private let internalsThunk: () -> Internals
    
    // TODO: maybe don't set this but leave as transform?
    public private(set) var state: State
    public var internals: Internals { internalsThunk() }
    
    public init<E: Engine>(
        engine: E,
        state toLocalState: @escaping (E.State) -> State,
        action fromLocalAction: @escaping (Action) -> E.Action
    ) {
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            engine.send(fromLocalAction(action))
        }
        stateThunk = {
            toLocalState(engine.state)
        }
        internalsThunk = {
            engine.internals
        }
        state = stateThunk() // initialize
        
        stateDidChange()
    }
    
    @MainActor
    public func send(_ action: Action) {
        sendThunk(action)
    }
}

func startObserving<T>(_ makeValue: @escaping () ->T, onChange: @escaping (T) -> Void) {
    let value = withObservationTracking {
        makeValue()
    } onChange: {
        Task {
            startObserving(makeValue, onChange: onChange)
        }
    }
    onChange(value)
}

private extension MapEngine {
    func stateDidChange() {
        startObserving(stateThunk, onChange: { [weak self] newState in
            self?.state = newState
        })
    }
}

public extension Engine {
    func map<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> MapEngine<LocalState, LocalAction> {
        MapEngine(engine: self, state: toLocalState, action: fromLocalAction)
    }
}
