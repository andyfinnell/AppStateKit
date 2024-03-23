import Foundation

public struct SubscriptionID: Hashable {
    private let id: UUID
    
    public init() {
        id = UUID()
    }
}
