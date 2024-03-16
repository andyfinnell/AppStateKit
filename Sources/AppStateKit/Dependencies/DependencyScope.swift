
// TODO: need some flags to pass around so can construct things differently

/// A tree structure of dependencies. Can construct `Dependable` instances
/// when requested, and cache them off. It inherits dependencies from its
/// parents.
public final class DependencyScope {
    private var dependencies = [ObjectIdentifier: Any]()
    
    /// Create an empty `DependencySpace`
    public init() {}
    
    init(_ parentSpaces: DependencyScope) {
        for (key, value) in parentSpaces.dependencies {
            dependencies[key] = value
        }
    }
    
    /// Find or create a specific dependency
    public subscript<D: Dependable>(key: D.Type) -> D.T {
        let id = ObjectIdentifier(D.self)
        if let cached = dependencies[id] as? D.T {
            return cached
        } else {
            let dependency = D.makeDefault(with: self)
            dependencies[id] = dependency
            return dependency
        }
    }
    
    /// Ensure that the dependencies specified by the scope are created
    public func scoped<each D: Dependable>(_ scope: Scope<repeat each D>) -> DependencyScope {
        let childSpace = DependencyScope(self)
        scope.initialize(childSpace)
        return childSpace
    }
}
