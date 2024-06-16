import Foundation

@MainActor
public final class MapEngine<State, Action: Sendable, Output>: Engine {
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> State
    private let internalsThunk: () -> Internals
    private let signalThunk: @MainActor (Output) -> Void

    public var state: State { stateThunk() }
    public let statePublisher: any Publisher<State>
    public var internals: Internals { internalsThunk() }
    
    public init<E: Engine>(
        engine: E,
        state toLocalState: @escaping (E.State) -> State,
        action fromLocalAction: @escaping (Action) -> E.Action,
        translate: @escaping (Output) -> E.Action?
    ) {
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            engine.send(fromLocalAction(action))
        }
        // Intentionally holding parent in memory
        signalThunk = { @MainActor output in
            guard let parentAction = translate(output) else {
                return
            }
            engine.send(parentAction)
        }

        stateThunk = {
            toLocalState(engine.state)
        }
        statePublisher = engine.statePublisher.map(toLocalState)
        
        internalsThunk = {
            engine.internals
        }
    }
    
    public func send(_ action: Action) {
        sendThunk(action)
    }
    
    public func signal(_ output: Output) {
        signalThunk(output)
    }
}

public extension Engine {
    func map<LocalState, LocalAction, LocalOutput>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action,
        translate: @escaping (LocalOutput) -> Action?
    ) -> MapEngine<LocalState, LocalAction, LocalOutput> {
        MapEngine(
            engine: self,
            state: toLocalState,
            action: fromLocalAction,
            translate: translate
        )
    }
    
    func map<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> MapEngine<LocalState, LocalAction, Never> {
        MapEngine(
            engine: self,
            state: toLocalState,
            action: fromLocalAction,
            translate: { _ in nil }
        )
    }

}
