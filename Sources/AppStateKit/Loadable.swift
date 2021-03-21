import Foundation

public enum Loadable<T> {
    case idle
    case loading
    case loaded(T)
}

extension Loadable: Equatable where T: Equatable {
    
}
