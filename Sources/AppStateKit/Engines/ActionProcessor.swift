@MainActor
final class ActionProcessor<State, Action: Sendable, Output> {
    private var actions = [Action]()
    private var subscriptions = [SubscriptionID: Task<Void, Never>]()
    private var isProcessing = false
    private let reduce: (inout State, Action, AnySideEffects<Action, Output>) -> Void
    private let dependencies: DependencyScope

    init(
        dependencies: DependencyScope,
        reduce: @escaping (inout State, Action, AnySideEffects<Action, Output>) -> Void
    ) {
        self.dependencies = dependencies
        self.reduce = reduce
    }
    
    var internals: Internals {
        Internals(dependencyScope: dependencies)
    }
    
    func process(
        _ action: Action,
        on getState: () -> State,
        _ setState: (State) -> Void,
        using sendThunk: @MainActor @Sendable @escaping (Action) -> Void,
        _ signalThunk: @MainActor @escaping (Output) -> Void
    ) {
        actions.append(action)
        processNextActionIfPossible(
            on: getState,
            setState,
            using: sendThunk,
            signalThunk
        )
    }
}

private extension ActionProcessor {
    func processNextActionIfPossible(
        on getState: () -> State,
        _ setState: (State) -> Void,
        using sendThunk: @MainActor @Sendable @escaping (Action) -> Void,
        _ signalThunk: @MainActor @escaping (Output) -> Void
    ) {
        guard !isProcessing,
              let nextAction = actions.first else {
            return
        }
        isProcessing = true
        actions.removeFirst()
        let sideEffects = SideEffectsContainer<Action>(dependencyScope: dependencies)
        var state = getState()
        reduce(&state, nextAction, sideEffects.eraseToAnySideEffects(signal: signalThunk))
        setState(state)
        isProcessing = false
        
        // Perform effects
        sideEffects.apply(using: sendThunk)
        
        // Start subscriptions
        sideEffects.startSubscriptions(
            using: sendThunk,
            attachingWith: { task, subscriptionID in
                self.subscriptions[subscriptionID] = task
            },
            onFinish: { @MainActor [weak self] subscriptionID in
                guard let self else {
                    return
                }
                self.subscriptions.removeValue(forKey: subscriptionID)
            })
        
        // Cancel any subscriptions
        for subscriptionID in sideEffects.cancellations {
            guard let task = subscriptions[subscriptionID] else {
                return
            }
            task.cancel()
            subscriptions.removeValue(forKey: subscriptionID)
        }
        
        // recurse
        processNextActionIfPossible(on: getState, setState, using: sendThunk, signalThunk)
    }
}
