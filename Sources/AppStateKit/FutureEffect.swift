import Foundation

infix operator ~>

public struct FutureEffect<ReturnType> {
    private let handler: () async -> ReturnType
    
    public init(_ handler: @escaping () async -> ReturnType) {
        self.handler = handler
    }
    
    public func map<R>(_ transform: @escaping (ReturnType) -> R) -> FutureEffect<R> {
        FutureEffect<R> {
            await transform(handler())
        }
    }
    
    public static func ~> <R>(lhs: FutureEffect<ReturnType>, rhs: @escaping (ReturnType) -> R) -> FutureEffect<R> {
        lhs.map(rhs)
    }

    func call() async -> ReturnType {
        await handler()
    }
}

public extension FutureEffect where ReturnType == Void {
    static func ~> <R>(lhs: FutureEffect<Void>, rhs: R) -> FutureEffect<R> {
        lhs.map { _ in rhs }
    }

}
