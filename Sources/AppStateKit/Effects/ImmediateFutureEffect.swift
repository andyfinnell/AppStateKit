import Foundation

struct FutureImmediateEffect<ReturnType>: Sendable {
    private let handler: @MainActor () -> ReturnType
    
    init(_ handler: @MainActor @escaping () -> ReturnType) {
        self.handler = handler
    }
    
    func map<R>(_ transform: @Sendable @escaping (ReturnType) -> R) -> FutureImmediateEffect<R> {
        FutureImmediateEffect<R> {
            transform(handler())
        }
    }
    
    @MainActor
    func call() -> ReturnType {
        handler()
    }
}
