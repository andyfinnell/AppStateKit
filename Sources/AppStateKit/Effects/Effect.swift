
/// Represents an effect
public struct Effect<ReturnType, Failure: Error, each ParameterType>: Sendable {
    private let thunk: @Sendable (repeat each ParameterType) async -> Result<ReturnType, Failure>

    public init(_ impl: @Sendable @escaping (repeat each ParameterType) async -> Result<ReturnType, Failure>) {
        thunk = impl
    }

    func perform(_ parameters: repeat each ParameterType) async -> Result<ReturnType, Failure> {
        await thunk(repeat each parameters)
    }
}

