import Foundation

final actor AsyncSet<T: Hashable> {
    var set = Set<T>()
    
    func insert(_ value: T) {
        set.insert(value)
    }
}
