import Foundation

public final class MapEngine<State, Action>: Engine {
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> State
    private let internalsThunk: () -> Internals
    
    public var state: State { stateThunk() }
    public let statePublisher: any Publisher<State>
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
        statePublisher = engine.statePublisher.map(toLocalState)
        
        internalsThunk = {
            engine.internals
        }
    }
    
    @MainActor
    public func send(_ action: Action) {
        sendThunk(action)
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
