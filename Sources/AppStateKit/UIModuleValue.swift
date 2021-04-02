import Foundation
import Combine

public struct UIModuleValue<State, Action, Effect, Environment> {
    let reducer: (State, Action, SideEffects<Effect>) -> State
    let sideEffectHandler: (Effect, Environment) -> AnyPublisher<Action, Never>

    public init(reducer: @escaping (State, Action, SideEffects<Effect>) -> State, sideEffectHandler: @escaping (Effect, Environment) -> AnyPublisher<Action, Never>) {
        self.reducer = reducer
        self.sideEffectHandler = sideEffectHandler
    }
        
    public static func combine(_ modules: Self...) -> Self {
        Self(reducer: { state, action, sideEffect in
            modules.reduce(state) { $1.reducer($0, action, sideEffect) }
        }, sideEffectHandler: { effect, environment in
            Publishers.MergeMany(
                modules.map { $0.sideEffectHandler(effect, environment) }
            ).eraseToAnyPublisher()
        })
    }
    
    public func external<GlobalAction, GlobalEffect>(
        toLocalAction: @escaping (GlobalAction) -> Action?,
        fromLocalAction: @escaping (Action) -> GlobalAction,
        toLocalEffect: @escaping (GlobalEffect) -> Effect?,
        fromLocalEffect: @escaping (Effect) -> GlobalEffect
    ) -> UIModuleValue<State, GlobalAction, GlobalEffect, Environment> {
        UIModuleValue<State, GlobalAction, GlobalEffect, Environment>(reducer: { state, globalAction, globalSideEffects in
            guard let localAction = toLocalAction(globalAction) else {
                return state
            }
            let localSideEffects = SideEffects<Effect>()
            let newState = self.reducer(state, localAction, localSideEffects)
            globalSideEffects.combine(localSideEffects, using: fromLocalEffect)
            
            return newState
        }, sideEffectHandler: { effect, environment in
            guard let localEffect = toLocalEffect(effect) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            return self.sideEffectHandler(localEffect, environment)
                .map { fromLocalAction($0) }
                .eraseToAnyPublisher()
        })
    }

    
    public func property<GlobalState: Updatable, GlobalAction, GlobalEffect, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, State>,
        toLocalAction: @escaping (GlobalAction) -> Action?,
        fromLocalAction: @escaping (Action) -> GlobalAction,
        toLocalEffect: @escaping (GlobalEffect) -> Effect?,
        fromLocalEffect: @escaping (Effect) -> GlobalEffect,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment> {
        UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment>(reducer: { globalState, globalAction, globalSideEffect in
            guard let localAction = toLocalAction(globalAction) else {
                return globalState
            }
            let localSideEffects = SideEffects<Effect>()
            let localState = self.reducer(globalState[keyPath: state],
                                          localAction,
                                          localSideEffects)
            
            globalSideEffect.combine(localSideEffects, using: fromLocalEffect)
            
            return globalState.update(state, to: localState)
        }, sideEffectHandler: { effect, environment in
            guard let localEffect = toLocalEffect(effect) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            
            return self.sideEffectHandler(localEffect, toLocalEnvironment(environment))
                .map { fromLocalAction($0) }
                .eraseToAnyPublisher()
        })
    }
    
    public func optional() -> UIModuleValue<State?, Action, Effect, Environment> {
        UIModuleValue<State?, Action, Effect, Environment>(reducer: { optionalState, action, sideEffect in
            guard let state = optionalState else {
                return nil
            }
            return self.reducer(state, action, sideEffect)
        }, sideEffectHandler: self.sideEffectHandler)
    }
    
    public func array<GlobalState: Updatable, GlobalAction, GlobalEffect, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, Int)?,
        fromLocalAction: @escaping (Action, Int) -> GlobalAction,
        toLocalEffect: @escaping (GlobalEffect) -> (Effect, Int)?,
        fromLocalEffect: @escaping (Effect, Int) -> GlobalEffect,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment> {
        UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment>(reducer: { globalState, globalAction, globalSideEffect in
            guard let (localAction, localIndex) = toLocalAction(globalAction) else {
                return globalState
            }
            guard localIndex >= globalState[keyPath: state].startIndex && localIndex < globalState[keyPath: state].endIndex else {
                return globalState
            }
            let localSideEffect = SideEffects<Effect>()
            let localState = self.reducer(globalState[keyPath: state][localIndex],
                                          localAction,
                                          localSideEffect)
            globalSideEffect.combine(localSideEffect, using: { fromLocalEffect($0, localIndex) })

            return globalState.update(state, to: globalState[keyPath: state].update(localIndex, to: localState))
        }, sideEffectHandler: { globalEffect, globalEnvironment in
            guard let (localEffect, localIndex) = toLocalEffect(globalEffect) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            
            return self.sideEffectHandler(localEffect, toLocalEnvironment(globalEnvironment))
                .map { fromLocalAction($0, localIndex) }
                .eraseToAnyPublisher()
        })
    }
    
    public func arrayById<GlobalState: Updatable, GlobalAction, GlobalEffect, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, State.ID)?,
        fromLocalAction: @escaping (Action, State.ID) -> GlobalAction,
        toLocalEffect: @escaping (GlobalEffect) -> (Effect, State.ID)?,
        fromLocalEffect: @escaping (Effect, State.ID) -> GlobalEffect,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment> where State: Identifiable {
        UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment>(reducer: { globalState, globalAction, globalSideEffect in
            guard let (localAction, localId) = toLocalAction(globalAction),
                  let localIndex =  globalState[keyPath: state].firstIndex(where: { $0.id == localId }) else {
                return globalState
            }
            let localSideEffect = SideEffects<Effect>()
            let localState = self.reducer(globalState[keyPath: state][localIndex],
                                          localAction,
                                          localSideEffect)
            globalSideEffect.combine(localSideEffect, using: { fromLocalEffect($0, localId) })

            return globalState.update(state, to: globalState[keyPath: state].update(localIndex, to: localState))
        }, sideEffectHandler: { globalEffect, globalEnvironment in
            guard let (localEffect, localId) = toLocalEffect(globalEffect) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            
            return self.sideEffectHandler(localEffect, toLocalEnvironment(globalEnvironment))
                .map { fromLocalAction($0, localId) }
                .eraseToAnyPublisher()
        })
    }

    public func dictionary<Key: Hashable, GlobalState: Updatable, GlobalAction, GlobalEffect, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [Key: State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, Key)?,
        fromLocalAction: @escaping (Action, Key) -> GlobalAction,
        toLocalEffect: @escaping (GlobalEffect) -> (Effect, Key)?,
        fromLocalEffect: @escaping (Effect, Key) -> GlobalEffect,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment> {
        UIModuleValue<GlobalState, GlobalAction, GlobalEffect, GlobalEnvironment>(reducer: { globalState, globalAction, globalSideEffect in
            guard let (localAction, localKey) = toLocalAction(globalAction),
                  let inputLocalState =  globalState[keyPath: state][localKey] else {
                return globalState
            }
            let localSideEffect = SideEffects<Effect>()
            let localState = self.reducer(inputLocalState,
                                          localAction,
                                          localSideEffect)
            globalSideEffect.combine(localSideEffect, using: { fromLocalEffect($0, localKey) })

            return globalState.update(state, to: globalState[keyPath: state].update(localKey, to: localState))
        }, sideEffectHandler: { globalEffect, globalEnvironment in
            guard let (localEffect, localKey) = toLocalEffect(globalEffect) else {
                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            
            return self.sideEffectHandler(localEffect, toLocalEnvironment(globalEnvironment))
                .map { fromLocalAction($0, localKey) }
                .eraseToAnyPublisher()
        })
    }
}

