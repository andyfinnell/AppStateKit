/// A type that describes what dependencies should be created at this scope
/// Used to control lifetimes of dependencies.
public struct Scope<each D> where repeat each D: Dependable {
    public init() {}
    
    @MainActor
    func initialize(_ space: DependencyScope) {
        _ = (repeat (space[(each D).self]))
    }
}
