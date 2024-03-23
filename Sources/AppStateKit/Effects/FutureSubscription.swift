import Foundation

struct FutureSubscription<ReturnType> {
    let id: SubscriptionID
    private let handler: ((ReturnType) async -> Void) async throws -> Void
    
    init(id: SubscriptionID, handler: @escaping ((ReturnType) async -> Void) async throws -> Void) {
        self.id = id
        self.handler = handler
    }
    
    func map<R>(_ transform: @escaping (ReturnType) -> R) -> FutureSubscription<R> {
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
