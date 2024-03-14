
/// Represents an effect
public struct Effect<ReturnType, Failure: Error, each ParameterType> {
    private let thunk: (repeat each ParameterType) async -> Result<ReturnType, Failure>

    // TODO: can we make this easier to construct, without the Result?
    public init(_ impl: @escaping (repeat each ParameterType) async -> Result<ReturnType, Failure>) {
        thunk = impl
    }

    func perform(_ parameters: repeat each ParameterType) async -> Result<ReturnType, Failure> {
        await thunk(repeat each parameters)
    }
}

