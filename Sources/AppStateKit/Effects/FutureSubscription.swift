import Foundation

struct FutureSubscription<ReturnType>: Sendable {
    let id: SubscriptionID
    private let handler: @Sendable ((ReturnType) async -> Void) async throws -> Void
    
    init(id: SubscriptionID, handler: @Sendable @escaping ((ReturnType) async -> Void) async throws -> Void) {
        self.id = id
        self.handler = handler
    }
    
    func map<R>(_ transform: @Sendable @escaping (ReturnType) -> R) -> FutureSubscription<R> {
        FutureSubscription<R>(id: id) { yield in
            try await handler() { v in
                await yield(transform(v))
            }
        }
    }
    
    func call(yield: (ReturnType) async -> Void) async throws -> Void {
        try await handler(yield)
    }
}
