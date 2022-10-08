import Foundation

protocol CapturedEffect<ReturnType> {
    associatedtype ReturnType
    
    func call() async -> ReturnType
}

struct EffectInstance<Parameters, ReturnType>: CapturedEffect {
    let parameters: Parameters
    let handler: (Parameters) async -> ReturnType
    
    func call() async -> ReturnType {
        await handler(parameters)
    }
}
