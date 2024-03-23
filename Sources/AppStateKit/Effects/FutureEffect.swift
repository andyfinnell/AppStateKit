import Foundation

struct FutureEffect<ReturnType> {
    private let handler: () async -> ReturnType
    
    init(_ handler: @escaping () async -> ReturnType) {
        self.handler = handler
    }
    
    func map<R>(_ transform: @escaping (ReturnType) -> R) -> FutureEffect<R> {
        FutureEffect<R> {
            await transform(handler())
        }
    }
    
    func call() async -> ReturnType {
        await handler()
    }
}
