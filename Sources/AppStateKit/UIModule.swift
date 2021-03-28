import Foundation
import Combine

public protocol UIModule {
    associatedtype State
    associatedtype Action
    associatedtype Effect
    associatedtype Environment

    associatedtype InternalAction
    associatedtype InternalEffect

    static func performSideEffect(_ effect: InternalEffect, in environment: Environment) -> AnyPublisher<InternalAction, Never>
    static func reduce(_ state: State, action: InternalAction, sideEffects: SideEffects<InternalEffect>) -> State
    static var internalValue: UIModuleValue<State, InternalAction, InternalEffect, Environment> { get }

    static var value: UIModuleValue<State, Action, Effect, Environment> { get }
    
    typealias Store = AppStateKit.Store<State, Action, Effect, Environment>

    static func makeStore(initialState: State, environment: Environment) -> Store
}

public extension UIModule {
    static var internalValue: UIModuleValue<State, InternalAction, InternalEffect, Environment> {
        UIModuleValue(reducer: reduce, sideEffectHandler: performSideEffect)
    }

    static func makeStore(initialState: State, environment: Environment) -> Store {
        Store(initialState: initialState,
              environment: environment,
              module: value)
    }
}

public extension UIModule where State: DefaultInitializable {
    static func makeStore(environment: Environment) -> Store {
        makeStore(initialState: State(), environment: environment)
    }
}
