import Foundation

public protocol Updatable {
    func update<T>(_ keyPath: WritableKeyPath<Self, T>, to value: T) -> Self
}

public extension Updatable {
    func update<T>(_ keyPath: WritableKeyPath<Self, T>, to value: T) -> Self {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

public extension Array {
    func update(_ index: Index, to value: Element) -> Self {
        guard index >= startIndex && index < endIndex else { return self }
        
        var copy = self
        copy[index] = value
        return copy
    }
}

public extension Array where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        first(where: { $0.id == id })
    }
    
    func update(_ id: Element.ID, to value: Element) -> Self {
        guard let index = firstIndex(where: { $0.id == id }) else {
            return self
        }
        var copy = self
        copy[index] = value
        return copy
    }
}

public extension Dictionary {
    func update(_ key: Key, to value: Value) -> Self {
        var copy = self
        copy.updateValue(value, forKey: key)
        return copy
    }
}
