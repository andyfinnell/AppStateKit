
// TODO: need some flags to pass around so can construct things differently

/// A tree structure of dependencies. Can construct `Dependable` instances
/// when requested, and cache them off. It inherits dependencies from its
/// parents.
@MainActor
public final class DependencyScope {
    private let parentScope: DependencyScope?
    private var dependencies = [ObjectIdentifier: Any]()
    
    /// Create an empty `DependencyScope`
    public init() {
        parentScope = nil
    }
    
    init(_ parentScope: DependencyScope) {
        self.parentScope = parentScope
    }
    
    /// Find or create a specific dependency
    public subscript<D: Dependable>(key: D.Type) -> D.T {
        get {
            let id = ObjectIdentifier(D.self)
            if let cached = cached(id: id, as: D.T.self) {
                return cached
            } else {
                let dependency = D.makeDefault(with: self)
                addToCache(dependency, forID: id, dependency: D.self)
                return dependency
            }
        }
        set {
            let id = ObjectIdentifier(D.self)
            addToCache(newValue, forID: id, dependency: D.self)
        }
    }

    public subscript<D: Dependable, W>(key: D.Type) -> D.T where D.T == Optional<W> {
        get {
            let id = ObjectIdentifier(D.self)
            if let cached = cached(id: id, as: W.self) {
                return cached
            } else {
                let dependency = D.makeDefault(with: self)
                addToCache(dependency, forID: id, dependency: D.self)
                return dependency
            }
        }
        set {
            let id = ObjectIdentifier(D.self)
            addToCache(newValue, forID: id, dependency: D.self)
        }
    }

    /// Ensure that the dependencies specified by the scope are created
    public func scoped<each D: Dependable, each I: Dependable>(
        _ scope: Scope<repeat each D>,
        injecting injections: repeat Injection<each I>
    ) -> DependencyScope {
        let childScope = DependencyScope(self)
        repeat (each injections).initialize(childScope)
        scope.initialize(childScope)
        return childScope
    }
    
    public func scoped(inject: (DependencyScope) -> Void) -> DependencyScope {
        let childScope = DependencyScope(self)
        inject(childScope)
        return childScope
    }
}

private extension DependencyScope {
    func cached<T>(id: ObjectIdentifier, as type: T.Type) -> T? {
        if let value = dependencies[id] as? T {
            return value
        } else {
            return parentScope?.cached(id: id, as: type)
        }
    }
    
    func addToCache<D: Dependable, T>(_ value: T, forID id: ObjectIdentifier, dependency: D.Type) {
        if D.isGlobal {
            addToGlobalCache(value, forID: id)
        } else {
            dependencies[id] = value
        }
    }
    
    func addToGlobalCache<T>(_ value: T, forID id: ObjectIdentifier) {
        if let parentScope {
            parentScope.addToGlobalCache(value, forID: id)
        } else {
            dependencies[id] = value
        }
    }
}
