import Foundation
import Observation

@Observable
public final class MainEngine<State, Action>: Engine {
    private let processor: ActionProcessor<State, Action>
    public private(set) var state: State
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
    }
    
    @MainActor
    public func send(_ action: Action) {
        processor.process(action, on: &state, using: { @MainActor [weak self] action in
            self?.send(action)
        })
    }
}
