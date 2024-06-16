import Foundation

public struct SubscriptionID: Hashable, Sendable {
    private let id: UUID
    
    public init() {
        id = UUID()
    }
}
