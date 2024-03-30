
public struct Injection<D: Dependable> {
    private let keyPath: ReferenceWritableKeyPath<DependencyScope, D.T>
    private let value: D.T
    
    public init(_ value: D.T, for keyPath: ReferenceWritableKeyPath<DependencyScope, D.T>) {
        self.keyPath = keyPath
        self.value = value
    }
    
    func initialize(_ scope: DependencyScope) {
        scope[keyPath: keyPath] = value
    }
}
