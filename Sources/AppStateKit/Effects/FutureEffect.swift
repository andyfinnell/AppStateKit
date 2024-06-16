import Foundation

struct FutureEffect<ReturnType>: Sendable {
    private let handler: @Sendable () async -> ReturnType
    
    init(_ handler: @Sendable @escaping () async -> ReturnType) {
        self.handler = handler
    }
    
    func map<R>(_ transform: @Sendable @escaping (ReturnType) -> R) -> FutureEffect<R> {
        FutureEffect<R> {
            await transform(handler())
        }
    }
    
    func call() async -> ReturnType {
        await handler()
    }
}
