/// Protocol that describes how to construct a type. i.e. a factory
public protocol Dependable {
    /// The type that will be constructed
    associatedtype T
    
    /// Factory method that creates the default value. It is unfailable,
    /// meaning it will always return a valid value. It's passed in the
    /// current dependency space so it can find its own dependencies.
    @MainActor
    static func makeDefault(with space: DependencyScope) -> T
}
