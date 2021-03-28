import Foundation
import Combine

// TODO: module might be a better name than component. 
public protocol UIComponent {
    associatedtype State
    associatedtype Action
    associatedtype Effect
    associatedtype Environment

    associatedtype InternalAction
    associatedtype InternalEffect

    static func performSideEffect(_ effect: InternalEffect, in environment: Environment) -> AnyPublisher<InternalAction, Never>
    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffect<InternalEffect>) -> State
    static var internalValue: UIComponentValue<State, InternalAction, InternalEffect, Environment> { get }

    static var value: UIComponentValue<State, Action, Effect, Environment> { get }
    
    typealias Store = AppStateKit.Store<State, Action, Effect, Environment>

    static func makeStore(initialState: State, environment: Environment) -> Store
}

public extension UIComponent {
    static var internalValue: UIComponentValue<State, InternalAction, InternalEffect, Environment> {
        UIComponentValue(reducer: reduce, sideEffectHandler: performSideEffect)
    }

    static func makeStore(initialState: State, environment: Environment) -> Store {
        Store(initialState: initialState,
              environment: environment,
              component: value)
    }
    
    static func externalize<InternalAction>(_ internalReducer: @escaping (State, InternalAction, SideEffect<Effect>) -> State, toLocalAction: @escaping (Action) -> InternalAction?) -> (State, Action, SideEffect<Effect>) -> State {
        { state, globalAction, sideEffect in
            guard let localAction = toLocalAction(globalAction) else {
                return state
            }
            return internalReducer(state, localAction, sideEffect)
        }
    }
}

public extension UIComponent where State: DefaultInitializable {
    static func makeStore(environment: Environment) -> Store {
        makeStore(initialState: State(), environment: environment)
    }
}
