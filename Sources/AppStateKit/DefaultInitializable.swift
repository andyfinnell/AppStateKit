import Foundation

public protocol DefaultInitializable {
    init()
}

public extension Optional where Wrapped: DefaultInitializable {
    func withFallback() -> Wrapped {
        self ?? Wrapped()
    }
}
