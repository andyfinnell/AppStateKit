import Foundation

@MainActor
public final class MapEngine<State, Action: Sendable, Output>: Engine {
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> State
    private let internalsThunk: () -> Internals
    private let signalThunk: @MainActor (Output) -> Void
    private let detachmentContainer: any DetachmentContainer
    public var state: State { stateThunk() }
    public let statePublisher: any Publisher<State>
    public var internals: Internals { internalsThunk() }
    
    public init<E: Engine>(
        engine: E,
        state toLocalState: @escaping (E.State) -> State,
        action fromLocalAction: @escaping (Action) -> E.Action,
        translate: @escaping (Output) -> TranslateResult<E.Action, E.Output>
    ) {
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            engine.send(fromLocalAction(action))
        }
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

        stateThunk = {
            toLocalState(engine.state)
        }
        statePublisher = engine.statePublisher.map(toLocalState)
        
        internalsThunk = {
            engine.internals
        }
        detachmentContainer = engine
    }
    
    public func send(_ action: Action) {
        sendThunk(action)
    }
    
    public func signal(_ output: Output) {
        signalThunk(output)
    }
    
    public func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        detachmentContainer.attach(sender, at: key)
    }
}

public extension Engine {
    func map<LocalState, LocalAction, LocalOutput>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action,
        translate: @escaping (LocalOutput) -> TranslateResult<Action, Output>
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
            translate: { _ -> TranslateResult<Action, Output> in }
        )
    }

}
