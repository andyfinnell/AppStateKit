
public struct AnySideEffects<Action> {
    private let dependencyScope: DependencyScope
    private let append: (FutureEffect<Action>) -> Void
    
    init(
        dependencyScope: DependencyScope,
        append: @escaping (FutureEffect<Action>) -> Void
    ) {
        self.dependencyScope = dependencyScope
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
    
    public func tryPerform<each ParameterType, ReturnType, Failure: Error>(
        _ effect: KeyPath<DependencyScope, Effect<ReturnType, Failure, repeat each ParameterType>>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action,
        onFailure: @escaping (Failure) async -> Action
    ) {
        tryPerform(
            dependencyScope[keyPath: effect],
            with: repeat each parameters,
            transform: transform,
            onFailure: onFailure
        )
    }
    
    public func perform<each ParameterType, ReturnType>(
        _ effect: KeyPath<DependencyScope, Effect<ReturnType, Never, repeat each ParameterType>>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action
    ) {
        perform(
            dependencyScope[keyPath: effect],
            with: repeat each parameters,
            transform: transform
        )
    }
    
    public func map<ToAction>(_ transform: @escaping (ToAction) -> Action) -> AnySideEffects<ToAction> {
        // TODO: maybe a good time to create a child dependencyScope?
        AnySideEffects<ToAction>(dependencyScope: dependencyScope) { (future: FutureEffect<ToAction>) -> Void in
            let newFuture = future.map(transform)
            append(newFuture)
        }
    }
}
