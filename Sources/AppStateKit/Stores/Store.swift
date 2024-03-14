import Foundation
import Combine

public final class Store<State, Action, Effects> {
    private let effects: Effects
    private var actions = [Action]()
    private var isProcessing = false
    private let reduce: (inout State, Action, Effects, SideEffects<Action>) -> Void
    private let dependencies = DependencySpace()
    
    @PublishedState public private(set) var state: State
    
    public init<R: Reducer>(
        state: State,
        effectsFactory: @escaping (DependencySpace) -> Effects,
        reducer: R
    ) where R.State == State, R.Action == Action, R.Effects == Effects {
        self.state = state
        self.effects = effectsFactory(dependencies)
        reduce = { reducer.reduce(&$0, action: $1, effects: $2, sideEffects: $3) }
    }
    
    @MainActor
    public func apply(_ action: Action) async {
        actions.append(action)
        await processNextActionIfPossible()
    }
}

extension Store: Storable {
    public var statePublisher: AnyPublisher<State, Never> { $state }
}

private extension Store {
    @MainActor
    func processNextActionIfPossible() async {
        guard !isProcessing,
              let nextAction = actions.first else {
            return
        }
        isProcessing = true
        actions.removeFirst()
        let sideEffects = SideEffects<Action>()
        reduce(&state, nextAction, effects, sideEffects)
        isProcessing = false
        
        await sideEffects.apply(using: apply)
        
        // recurse
        await processNextActionIfPossible()
    }
}
