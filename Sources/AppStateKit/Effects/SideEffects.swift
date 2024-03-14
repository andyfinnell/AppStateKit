import Foundation
import Combine

public final class SideEffects<Action> {
    private var futures: [FutureEffect<Action>]
    
    init(futures: [FutureEffect<Action>] = []) {
        self.futures = futures
    }
    
    public func perform<each ParameterType, ReturnType, Failure: Error>(
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

    func appending<FromAction>(
        _ other: SideEffects<FromAction>,
        using transform: @escaping (FromAction) -> Action
    ) {
        let transformedEffects = other.futures.map { $0.map(transform) }
        futures.append(contentsOf: transformedEffects)
    }
    
    func map<ToAction>(_ transform: @escaping (Action) -> ToAction) -> SideEffects<ToAction> {
        SideEffects<ToAction>(futures: futures.map { $0.map(transform) })
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
