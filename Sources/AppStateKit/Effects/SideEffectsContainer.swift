
final class SideEffectsContainer<Action> {
    private let dependencyScope: DependencyScope
    private var futures: [FutureEffect<Action>]
    
    init(dependencyScope: DependencyScope, futures: [FutureEffect<Action>] = []) {
        self.dependencyScope = dependencyScope
        self.futures = futures
    }
        
    func eraseToAnySideEffects() -> AnySideEffects<Action> {
        AnySideEffects<Action>(dependencyScope: dependencyScope) { (future: FutureEffect<Action>) -> Void in
            self.futures.append(future)
        }
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
}
