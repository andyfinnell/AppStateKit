import Foundation

public struct OptionalReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects<Action>
    
    public init<R: Reducer>(@ReducerBuilder builder: @escaping () -> R)
    where State == R.State?, Action == R.Action, Effects == R.Effects {
        impl = { state, action, effects -> SideEffects<Action> in
            guard var stateCopy = state else {
                return SideEffects.none
            }
            let sideEffects = builder().reduce(&stateCopy, action: action, effects: effects)
            state = stateCopy
            
            return sideEffects
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action> {
        impl(&state, action, effects)
    }
}
