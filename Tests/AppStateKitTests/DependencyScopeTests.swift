@testable import AppStateKit
import Testing

struct DependencyScopeTests {
    final class LocalDep: Dependable {
        init() {}
        
        static func makeDefault(with space: DependencyScope) -> LocalDep {
            LocalDep()
        }
    }
    
    final class GlobalDep: Dependable {
        init() {}
        
        static let isGlobal = true
        
        static func makeDefault(with space: DependencyScope) -> GlobalDep {
            GlobalDep()
        }
    }
    
    @MainActor
    @Test
    func testLocalDependency() {
        let parentScope = DependencyScope()
        let childScope1 = DependencyScope(parentScope)
        let childScope2 = DependencyScope(parentScope)
        
        let local1 = childScope1[LocalDep.self]
        let local2 = childScope2[LocalDep.self]
        #expect(local1 !== local2)
    }
    
    @MainActor
    @Test
    func testGlobalDependency() {
        let parentScope = DependencyScope()
        let childScope1 = DependencyScope(parentScope)
        let childScope2 = DependencyScope(parentScope)
        
        let global1 = childScope1[GlobalDep.self]
        let global2 = childScope2[GlobalDep.self]
        #expect(global1 === global2)
    }

}
