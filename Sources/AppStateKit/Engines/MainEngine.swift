import Foundation

public final class MainEngine<State, Action>: Engine {
    private let processor: ActionProcessor<State, Action>
    private let isEqual: (State, State) -> Bool
    private let _statePublisher = MainPublisher<State>()
    public private(set) var state: State
    public var statePublisher: any Publisher<State> { _statePublisher }
    public var internals: Internals { processor.internals }
    
    public init<C: BaseComponent>(
        dependencies: DependencyScope,
        state: State,
        component: C.Type
    ) where C.State == State, C.Action == Action {
        self.state = state
        processor = ActionProcessor(
            dependencies: dependencies,
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        isEqual = { _, _ in false } // assume worst case
    }

    public init<C: BaseComponent>(
        dependencies: DependencyScope,
        state: State,
        component: C.Type
    ) where C.State == State, C.Action == Action, State: Equatable {
        self.state = state
        processor = ActionProcessor(
            dependencies: dependencies,
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        isEqual = { $0 == $1 }
    }

    @MainActor
    public func send(_ action: Action) {
        processor.process(
            action,
            on: getState, setState,
            using: { @MainActor [weak self] action in
            self?.send(action)
        })
    }
}

private extension MainEngine {
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
