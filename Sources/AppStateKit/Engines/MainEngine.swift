import Foundation
import Observation

@Observable
public final class MainEngine<State, Action>: Engine {
    private var actions = [Action]()
    private var isProcessing = false
    private let reduce: (inout State, Action, AnySideEffects<Action>) -> Void
    private let dependencies: DependencyScope
    
    public private(set) var state: State
    
    public init<C: BaseComponent>(
        dependencies: DependencyScope,
        state: State,
        component: C.Type
    ) where C.State == State, C.Action == Action {
        self.dependencies = dependencies
        self.state = state
        reduce = { C.reduce(&$0, action: $1, sideEffects: $2) }
    }
    
    @MainActor
    public func send(_ action: Action) {
        actions.append(action)
        processNextActionIfPossible()
    }
}

private extension MainEngine {
    @MainActor
    func processNextActionIfPossible() {
        guard !isProcessing,
              let nextAction = actions.first else {
            return
        }
        isProcessing = true
        actions.removeFirst()
        let sideEffects = SideEffectsContainer<Action>(dependencyScope: dependencies)
        reduce(&state, nextAction, sideEffects.eraseToAnySideEffects())
        isProcessing = false
        
        let sendThunk = { @MainActor [weak self] (action: Action) -> Void in
            self?.send(action)
        }
        Task.detached {
            await sideEffects.apply(using: sendThunk)
        }
        
        // recurse
        processNextActionIfPossible()
    }
}
