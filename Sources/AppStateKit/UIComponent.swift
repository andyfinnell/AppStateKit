import Foundation

// TODO: how do we allocate one of these?
// TODO: how does that relate to the Store
public protocol UIComponent {
    associatedtype State
    associatedtype Action
    associatedtype Environment
        
    static var reducer: Reducer<State, Action, Environment> { get }
    
    typealias Store = AppStateKit.Store<State, Action, Environment>

    static func makeStore(initialState: State, environment: Environment) -> Store
}

public extension UIComponent {
    static func makeStore(initialState: State, environment: Environment) -> Store {
        Store(initialState: initialState,
              reducer: Self.reducer,
              environment: environment)
    }
    
}

public extension UIComponent where State: DefaultInitializable {
    static func makeStore(environment: Environment) -> Store {
        makeStore(initialState: State(), environment: environment)
    }
}

public extension UIComponent where Environment: DefaultInitializable {
    static func makeStore(initialState: State) -> Store {
        makeStore(initialState: initialState, environment: Environment())
    }
}

public extension UIComponent where State: DefaultInitializable, Environment: DefaultInitializable {
    static func makeStore() -> Store {
        makeStore(initialState: State(), environment: Environment())
    }
}
