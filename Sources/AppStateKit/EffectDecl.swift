import Foundation

public struct EffectDecl<Parameters, ReturnType> {
    private let handler: (Parameters) async -> ReturnType
    
    public init(_ handler: @escaping (Parameters) async -> ReturnType) {
        self.handler = handler
    }

    func callAsFunction(_ parameters: Parameters) -> EffectInstance<Parameters, ReturnType> {
        EffectInstance(parameters: parameters, handler: handler)
    }
}
