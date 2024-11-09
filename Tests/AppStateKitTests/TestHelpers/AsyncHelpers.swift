import Foundation

final actor AsyncSet<T: Hashable> {
    var set = Set<T>()
    
    init() {}
    
    init<S: Sequence>(_ sequence: S) where S.Element == T {
        set.formUnion(sequence)
    }
    
    func insert(_ value: T) {
        set.insert(value)
    }
}
