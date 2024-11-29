@MainActor
public struct AnySideEffects<Action: Sendable, Output> {
    private let dependencyScope: DependencyScope
    private let append: (FutureEffect<Action>) -> Void
    private let appendImmediate: (FutureImmediateEffect<Action>) -> Void
    private let signalThunk: (Output) -> Void
    private let subscribe: (FutureSubscription<Action>) -> Void
    private let cancelThunk: (SubscriptionID) -> Void
    private let detachedAction: (FutureDetachedAction) -> Void
    
    init(
        dependencyScope: DependencyScope,
        append: @escaping (FutureEffect<Action>) -> Void,
        appendImmediate: @escaping (FutureImmediateEffect<Action>) -> Void,
        signal: @escaping (Output) -> Void,
        subscribe: @escaping (FutureSubscription<Action>) -> Void,
        cancel: @escaping (SubscriptionID) -> Void,
        detachedAction: @escaping (FutureDetachedAction) -> Void
    ) {
        self.dependencyScope = dependencyScope
        self.append = append
        self.appendImmediate = appendImmediate
        self.signalThunk = signal
        self.subscribe = subscribe
        self.cancelThunk = cancel
        self.detachedAction = detachedAction
    }
        
    public func perform<each ParameterType: Sendable, ReturnType>(
        _ effect: Effect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) async -> Action
    ) {
        let tuple = (repeat each parameters)
        let future = FutureEffect {
            switch await effect.perform(repeat each tuple) {
            case let .success(value):
                return await transform(value)
            }
        }
        append(future)
    }

    public func perform<each ParameterType: Sendable, ReturnType, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) async -> Action
    ) where D.T == Effect<ReturnType, Never, repeat each ParameterType> {
        perform(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform
        )
    }

    public func tryPerform<each ParameterType: Sendable, ReturnType, Failure: Error>(
        _ effect: Effect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) async -> Action,
        onFailure: @Sendable @escaping (Failure) async -> Action
    ) {
        let tuple = (repeat each parameters)
        let future = FutureEffect {
            switch await effect.perform(repeat each tuple) {
            case let .success(value):
                return await transform(value)
            case let .failure(error):
                return await onFailure(error)
            }
        }
        append(future)
    }

    public func tryPerform<each ParameterType: Sendable, ReturnType, Failure: Error, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) async -> Action,
        onFailure: @Sendable @escaping (Failure) async -> Action
    ) where D.T == Effect<ReturnType, Failure, repeat each ParameterType> {
        tryPerform(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform,
            onFailure: onFailure
        )
    }

    public func perform<each ParameterType: Sendable, ReturnType>(
        _ effect: ImmediateEffect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) -> Action
    ) {
        let tuple = (repeat each parameters)
        let future = FutureImmediateEffect {
            switch effect.perform(repeat each tuple) {
            case let .success(value):
                return transform(value)
            }
        }
        appendImmediate(future)
    }

    public func perform<each ParameterType: Sendable, ReturnType, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) -> Action
    ) where D.T == ImmediateEffect<ReturnType, Never, repeat each ParameterType> {
        perform(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform
        )
    }

    public func tryPerform<each ParameterType: Sendable, ReturnType, Failure: Error>(
        _ effect: ImmediateEffect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) -> Action,
        onFailure: @Sendable @escaping (Failure) -> Action
    ) {
        let tuple = (repeat each parameters)
        let future = FutureImmediateEffect {
            switch effect.perform(repeat each tuple) {
            case let .success(value):
                return transform(value)
            case let .failure(error):
                return onFailure(error)
            }
        }
        appendImmediate(future)
    }

    public func tryPerform<each ParameterType: Sendable, ReturnType, Failure: Error, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType) -> Action,
        onFailure: @Sendable @escaping (Failure) -> Action
    ) where D.T == ImmediateEffect<ReturnType, Failure, repeat each ParameterType> {
        tryPerform(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform,
            onFailure: onFailure
        )
    }

    public func subscribe<each ParameterType: Sendable, ReturnType>(
        _ effect: Effect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType, (Action) async -> Void) async throws -> Void
    ) -> SubscriptionID {
        let id = SubscriptionID()
        let tuple = (repeat each parameters)
        let future = FutureSubscription(id: id) { yield in
            switch await effect.perform(repeat each tuple) {
            case let .success(value):
                try await transform(value, yield)
            }
        }
        subscribe(future)
        return id
    }

    public func subscribe<each ParameterType: Sendable, ReturnType, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType, (Action) async -> Void) async throws -> Void
    ) -> SubscriptionID where D.T == Effect<ReturnType, Never, repeat each ParameterType> {
        subscribe(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform
        )
    }

    public func trySubscribe<each ParameterType: Sendable, ReturnType, Failure: Error>(
        _ effect: Effect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType, (Action) async -> Void) async throws -> Void,
        onFailure: @Sendable @escaping (Failure) async -> Action
    ) -> SubscriptionID {
        let id = SubscriptionID()
        let tuple = (repeat each parameters)
        let future = FutureSubscription(id: id) { yield in
            switch await effect.perform(repeat each tuple) {
            case let .success(value):
                try await transform(value, yield)
            case let .failure(error):
                let action = await onFailure(error)
                await yield(action)
            }
        }
        subscribe(future)
        return id
    }

    public func trySubscribe<each ParameterType: Sendable, ReturnType, Failure: Error, D: Dependable>(
        _ effectType: D.Type,
        with parameters: repeat each ParameterType,
        transform: @Sendable @escaping (ReturnType, (Action) async -> Void) async throws -> Void,
        onFailure: @Sendable @escaping (Failure) async -> Action
    ) -> SubscriptionID where D.T == Effect<ReturnType, Failure, repeat each ParameterType> {
        trySubscribe(
            dependencyScope[effectType],
            with: repeat each parameters,
            transform: transform,
            onFailure: onFailure
        )
    }

    public func cancel(_ subscriptionID: SubscriptionID) {
        cancelThunk(subscriptionID)
    }

    public func map<ToAction, ToOutput>(
        _ transform: @Sendable @escaping (ToAction) -> Action,
        translate: @escaping (ToOutput) -> Action? = { _ in nil }
    ) -> AnySideEffects<ToAction, ToOutput> {
        // TODO: maybe a good time to create a child dependencyScope?
        AnySideEffects<ToAction, ToOutput>(
            dependencyScope: dependencyScope,
            append: { (future: FutureEffect<ToAction>) -> Void in
                let newFuture = future.map(transform)
                append(newFuture)
            },
            appendImmediate: { (future: FutureImmediateEffect<ToAction>) -> Void in
                let newFuture = future.map(transform)
                appendImmediate(newFuture)
            },
            signal: { output in
                guard let action = translate(output) else {
                    return
                }
                append(FutureEffect {
                    action
                })
            },
            subscribe: { subscription in
                let newSubscription = subscription.map(transform)
                subscribe(newSubscription)
            },
            cancel: cancelThunk,
            detachedAction: detachedAction
        )
    }
    
    public func schedule(_ action: Action) {
        append(FutureEffect {
            action
        })
    }
    
    public func schedule<D: Detachment>(_ action: D.DetachedAction, for key: D.Type) {
        detachedAction(FutureDetachedAction(action: action, target: key))
    }
    
    public func signal(_ output: Output) {
        signalThunk(output)
    }
}
