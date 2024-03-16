
public protocol SideEffects<Action> {
    associatedtype Action
    
    func tryPerform<each ParameterType, ReturnType, Failure: Error>(
        _ effect: Effect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action,
        onFailure: @escaping (Failure) async -> Action
    )
    
    func perform<each ParameterType, ReturnType>(
        _ effect: Effect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action
    )
    
    func map<ToAction>(_ transform: @escaping (ToAction) -> Action) -> AnySideEffects<ToAction>
}
