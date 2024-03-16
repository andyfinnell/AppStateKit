
final class SideEffectsContainer<Action>: SideEffects {
    private var futures: [FutureEffect<Action>]
    
    init(futures: [FutureEffect<Action>] = []) {
        self.futures = futures
    }
    
    public func tryPerform<each ParameterType, ReturnType, Failure: Error>(
        _ effect: Effect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action,
        onFailure: @escaping (Failure) async -> Action
    ) {
        let future = FutureEffect {
            switch await effect.perform(repeat each parameters) {
            case let .success(value):
                return await transform(value)
            case let .failure(error):
                return await onFailure(error)
            }
        }
        futures.append(future)
    }
    
    public func perform<each ParameterType, ReturnType>(
        _ effect: Effect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action
    ) {
        let future = FutureEffect {
            switch await effect.perform(repeat each parameters) {
            case let .success(value):
                return await transform(value)
            }
        }
        futures.append(future)
    }

    public func map<ToAction>(_ transform: @escaping (ToAction) -> Action) -> AnySideEffects<ToAction> {
        AnySideEffects<ToAction> { (future: FutureEffect<ToAction>) -> Void in
            let newFuture = future.map(transform)
            self.futures.append(newFuture)
        }
    }
    
    func eraseToAnySideEffects() -> AnySideEffects<Action> {
        AnySideEffects<Action> { (future: FutureEffect<Action>) -> Void in
            self.futures.append(future)
        }
    }

    func apply(using send: @escaping (Action) async -> Void) async {
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
