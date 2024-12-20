import Foundation

@MainActor
public final class MainEngine<State, Action: Sendable>: Engine {
    private let processor: ActionProcessor<State, Action, Output>
    private let isEqual: (State, State) -> Bool
    private let _statePublisher = MainPublisher<State>()
    private let detachedSender = DetachedSender()
    public private(set) var state: State
    public var statePublisher: any Publisher<State> { _statePublisher }
    public var internals: Internals { processor.internals }
    
    public typealias Output = Never
    
    public init<C: BaseComponent>(
        dependencies: DependencyScope,
        state: State,
        component: C.Type
    ) where C.State == State, C.Action == Action, C.Output == Output {
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
    ) where C.State == State, C.Action == Action, State: Equatable, C.Output == Output {
        self.state = state
        processor = ActionProcessor(
            dependencies: dependencies,
            reduce: { C.reduce(&$0, action: $1, sideEffects: $2) }
        )
        isEqual = { $0 == $1 }
    }

    public func send(_ action: Action) {
        processor.process(
            action,
            on: getState, setState,
            using: { @MainActor [weak self] action in
                self?.send(action)
            },
            { _ in  },
            detachedSender: detachedSender
        )
    }
    
    public func signal(_ output: Output) {
        // nop, always top level
    }
    
    public func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        detachedSender.attach(sender, at: key)
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
