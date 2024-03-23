
final class SideEffectsContainer<Action> {
    private let dependencyScope: DependencyScope
    private var futures: [FutureEffect<Action>]
    private(set) var subscriptions: [FutureSubscription<Action>]
    private(set) var cancellations: Set<SubscriptionID>
    
    init(dependencyScope: DependencyScope,
         futures: [FutureEffect<Action>] = [],
         subscriptions: [FutureSubscription<Action>] = [],
         cancellations: Set<SubscriptionID> = Set()) {
        self.dependencyScope = dependencyScope
        self.futures = futures
        self.subscriptions = subscriptions
        self.cancellations = cancellations
    }
        
    func eraseToAnySideEffects() -> AnySideEffects<Action> {
        AnySideEffects<Action>(
            dependencyScope: dependencyScope,
            append: { (future: FutureEffect<Action>) -> Void in
                self.futures.append(future)
            },
            subscribe: { subscription in
                self.subscriptions.append(subscription)
            },
            cancel: { subscriptionID in
                self.cancellations.insert(subscriptionID)
                self.subscriptions.removeAll(where: { $0.id == subscriptionID })
            }
        )
    }

    func apply(using send: @MainActor @escaping (Action) async -> Void) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for future in futures {
                taskGroup.addTask {
                    let action = await future.call()
                    await send(action)
                }
            }
        }
    }
    
    @MainActor
    func startSubscriptions(
        using send: @MainActor @escaping (Action) async -> Void,
        attachingWith attach: @MainActor @escaping (Task<Void, Never>, SubscriptionID) -> Void,
        onFinish: @MainActor @escaping (SubscriptionID) -> Void
    ) {
        for subscription in subscriptions {
            let task = Task.detached {
                do {
                    try await subscription.call(yield: send)
                } catch {
                    // assume it was a cancel
                }
                await onFinish(subscription.id)
            }
            attach(task, subscription.id)
        }
    }
}
