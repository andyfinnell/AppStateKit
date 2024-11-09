import SwiftUI

@propertyWrapper
public struct LazyState<Object: AnyObject>: DynamicProperty {
    private final class Ref {
        private let factory: () -> Object
        private var cache: Object?
        
        init(_ factory: @escaping () -> Object) {
            self.factory = factory
        }
        
        var object: Object {
            if let cache {
                return cache
            } else {
                let object = factory()
                self.cache = object
                return object
            }
        }
    }
    
    @State private var ref: Ref
    
    public init(wrappedValue factory: @autoclosure @escaping () -> Object) {
        self.ref = Ref(factory)
    }
    
    public init(initialValue factory: @autoclosure @escaping () -> Object) {
        self.ref = Ref(factory)
    }
    
    public init(factory: @escaping () -> Object) {
        self.ref = Ref(factory)
    }

    public var wrappedValue: Object {
        ref.object
    }
}
