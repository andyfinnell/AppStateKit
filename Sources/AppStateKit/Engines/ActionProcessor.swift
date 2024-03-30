
final class ActionProcessor<State, Action> {
    private var actions = [Action]()
    private var subscriptions = [SubscriptionID: Task<Void, Never>]()
    private var isProcessing = false
    private let reduce: (inout State, Action, AnySideEffects<Action>) -> Void
    private let dependencies: DependencyScope

    init(
        dependencies: DependencyScope,
        reduce: @escaping (inout State, Action, AnySideEffects<Action>) -> Void)
    {
        self.dependencies = dependencies
        self.reduce = reduce
    }
    
    var internals: Internals {
        Internals(dependencyScope: dependencies)
    }
    
    @MainActor
    func process(
        _ action: Action,
        on state: inout State,
        using sendThunk: @MainActor @escaping (Action) -> Void
    ) {
        actions.append(action)
        processNextActionIfPossible(on: &state, using: sendThunk)
    }
}

private extension ActionProcessor {
    @MainActor
    func processNextActionIfPossible(
        on state: inout State,
        using sendThunk: @MainActor @escaping (Action) -> Void
    ) {
        guard !isProcessing,
              let nextAction = actions.first else {
            return
        }
        isProcessing = true
        actions.removeFirst()
        let sideEffects = SideEffectsContainer<Action>(dependencyScope: dependencies)
        reduce(&state, nextAction, sideEffects.eraseToAnySideEffects())
        isProcessing = false
        
        // Perform effects
        Task.detached {
            await sideEffects.apply(using: sendThunk)
        }
        
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
        processNextActionIfPossible(on: &state, using: sendThunk)
    }
}
