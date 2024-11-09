
/// Represents an effect that must be executed on the MainActor, immediately after the reducer
public struct ImmediateEffect<ReturnType, Failure: Error, each ParameterType>: Sendable {
    private let thunk: @MainActor (repeat each ParameterType) -> Result<ReturnType, Failure>

    public init(_ impl: @MainActor @escaping (repeat each ParameterType) -> Result<ReturnType, Failure>) {
        thunk = impl
    }

    @MainActor
    func perform(_ parameters: repeat each ParameterType) -> Result<ReturnType, Failure> {
        thunk(repeat each parameters)
    }
}

