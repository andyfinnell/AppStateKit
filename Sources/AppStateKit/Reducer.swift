import Foundation

// TODO: does it make sense to model SideEffects as handler types with default implementations
public struct Reducer<State, Action, Environment> {
    private let closure: (State, Action, SideEffect<Environment, Action>) -> State
    
    public init(_ closure: @escaping (State, Action, SideEffect<Environment, Action>) -> State) {
        self.closure = closure
    }
    
    public func callAsFunction(state: State, action: Action, sideEffect: SideEffect<Environment, Action>) -> State {
        closure(state, action, sideEffect)
    }
    
    public static func combine(_ reducers: Self...) -> Self {
        Self { state, action, sideEffect in
            reducers.reduce(state) { $1(state: $0, action: action, sideEffect: sideEffect) }
        }
    }
    
    
    public func external<GlobalAction>(
        toLocalAction: @escaping (GlobalAction) -> Action?,
        fromLocalAction: @escaping (Action) -> GlobalAction
    ) -> Reducer<State, GlobalAction, Environment> {
        Reducer<State, GlobalAction, Environment> { state, globalAction, sideEffect in
            guard let localAction = toLocalAction(globalAction) else {
                return state
            }
            let localSideEffect = SideEffect<Environment, Action>()
            let updatedState = self(state: state,
                                    action: localAction,
                                    sideEffect: localSideEffect)
            sideEffect.combine(localSideEffect,
                               toGlobalAction: fromLocalAction)
            return updatedState
        }
    }

    
    public func property<GlobalState: Updatable, GlobalAction, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, State>,
        toLocalAction: @escaping (GlobalAction) -> Action?,
        fromLocalAction: @escaping (Action) -> GlobalAction,
        tolocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        Reducer<GlobalState, GlobalAction, GlobalEnvironment> { globalState, globalAction, globalSideEffect in
            guard let localAction = toLocalAction(globalAction) else {
                return globalState
            }
            let localSideEffect = SideEffect<Environment, Action>()
            let localState = self(state: globalState[keyPath: state],
                                  action: localAction,
                                  sideEffect: localSideEffect)
            globalSideEffect.combine(localSideEffect,
                                     toLocalEnvironment: tolocalEnvironment,
                                     toGlobalAction: fromLocalAction)
            return globalState.update(state, to: localState)
        }
    }
    
    public func optional() -> Reducer<State?, Action, Environment> {
        Reducer<State?, Action, Environment> { optionalState, action, sideEffect in
            guard let state = optionalState else {
                return nil
            }
            return self(state: state,
                        action: action,
                        sideEffect: sideEffect)
        }
    }
    
    public func array<GlobalState: Updatable, GlobalAction, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, Int)?,
        fromLocalAction: @escaping (Action, Int) -> GlobalAction,
        tolocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        Reducer<GlobalState, GlobalAction, GlobalEnvironment> { globalState, globalAction, globalSideEffect in
            guard let (localAction, localIndex) = toLocalAction(globalAction) else {
                return globalState
            }
            guard localIndex >= globalState[keyPath: state].startIndex && localIndex < globalState[keyPath: state].endIndex else {
                return globalState
            }
            let localSideEffect = SideEffect<Environment, Action>()
            let localState = self(state: globalState[keyPath: state][localIndex],
                                  action: localAction,
                                  sideEffect: localSideEffect)
            globalSideEffect.combine(localSideEffect,
                                     toLocalEnvironment: tolocalEnvironment,
                                     toGlobalAction: { fromLocalAction($0, localIndex) })
            
            // TODO: with/update not super composable. It'd be nice if it were
            return globalState.update(state, to: globalState[keyPath: state].update(localIndex, to: localState))
        }
    }
    
    public func arrayById<GlobalState: Updatable, GlobalAction, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, State.ID)?,
        fromLocalAction: @escaping (Action, State.ID) -> GlobalAction,
        tolocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> where State: Identifiable {
        Reducer<GlobalState, GlobalAction, GlobalEnvironment> { globalState, globalAction, globalSideEffect in
            guard let (localAction, localId) = toLocalAction(globalAction),
                  let localIndex =  globalState[keyPath: state].firstIndex(where: { $0.id == localId }) else {
                return globalState
            }
            let localSideEffect = SideEffect<Environment, Action>()
            let localState = self(state: globalState[keyPath: state][localIndex],
                                  action: localAction,
                                  sideEffect: localSideEffect)
            globalSideEffect.combine(localSideEffect,
                                     toLocalEnvironment: tolocalEnvironment,
                                     toGlobalAction: { fromLocalAction($0, localId) })
            
            // TODO: with/update not super composable. It'd be nice if it were
            return globalState.update(state, to: globalState[keyPath: state].update(localIndex, to: localState))
        }
    }

    public func dictionary<Key: Hashable, GlobalState: Updatable, GlobalAction, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, [Key: State]>,
        toLocalAction: @escaping (GlobalAction) -> (Action, Key)?,
        fromLocalAction: @escaping (Action, Key) -> GlobalAction,
        tolocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        Reducer<GlobalState, GlobalAction, GlobalEnvironment> { globalState, globalAction, globalSideEffect in
            guard let (localAction, localKey) = toLocalAction(globalAction),
                  let inputLocalState =  globalState[keyPath: state][localKey] else {
                return globalState
            }
            let localSideEffect = SideEffect<Environment, Action>()
            let localState = self(state: inputLocalState,
                                  action: localAction,
                                  sideEffect: localSideEffect)
            globalSideEffect.combine(localSideEffect,
                                     toLocalEnvironment: tolocalEnvironment,
                                     toGlobalAction: { fromLocalAction($0, localKey) })
            
            // TODO: with/update not super composable. It'd be nice if it were
            return globalState.update(state, to: globalState[keyPath: state].update(localKey, to: localState))
        }
    }
}
