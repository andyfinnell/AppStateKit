@MainActor
final class SideEffectsContainer<Action: Sendable> {
    private let dependencyScope: DependencyScope
    private(set) var futures: [FutureEffect<Action>]
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
        
    func eraseToAnySideEffects<ToOutput>(
        signal: @escaping (ToOutput) -> Void
    ) -> AnySideEffects<Action, ToOutput> {
        AnySideEffects<Action, ToOutput>(
            dependencyScope: dependencyScope,
            append: { (future: FutureEffect<Action>) -> Void in
                self.futures.append(future)
            },
            signal: signal,
            subscribe: { subscription in
                self.subscriptions.append(subscription)
            },
            cancel: { subscriptionID in
                self.cancellations.insert(subscriptionID)
                self.subscriptions.removeAll(where: { $0.id == subscriptionID })
            }
        )
    }
    
    func apply(using send: @Sendable @MainActor @escaping (Action) async -> Void) {
        let futures = self.futures
        Task.detached {
            await withTaskGroup(of: Void.self) { taskGroup in
                for future in futures {
                    taskGroup.addTask {
                        let action = await future.call()
                        await send(action)
                    }
                }
            }
        }
    }
    
    func startSubscriptions(
        using send: @Sendable @MainActor @escaping (Action) async -> Void,
        attachingWith attach: @MainActor @escaping (Task<Void, Never>, SubscriptionID) -> Void,
        onFinish: @Sendable @MainActor @escaping (SubscriptionID) -> Void
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
