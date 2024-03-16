
public struct AnySideEffects<Action>: SideEffects {
    private let append: (FutureEffect<Action>) -> Void
    
    init(append: @escaping (FutureEffect<Action>) -> Void) {
        self.append = append
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
        append(future)
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
        append(future)
    }

    public func map<ToAction>(_ transform: @escaping (ToAction) -> Action) -> AnySideEffects<ToAction> {
        AnySideEffects<ToAction> { (future: FutureEffect<ToAction>) -> Void in
            let newFuture = future.map(transform)
            append(newFuture)
        }
    }
}
