
public protocol ExposedInternal {
    associatedtype Dependency: Dependable
}

public struct Internals {
    let dependencyScope: DependencyScope
    
    @MainActor
    public subscript<E: ExposedInternal>(key: E.Type) -> E.Dependency.T {
        dependencyScope[key.Dependency]
    }
}

