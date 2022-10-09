import Foundation

public struct OptionalReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects2<Action>
    
    public init<R: Reducer>(@ReducerBuilder builder: @escaping () -> R)
    where State == R.State?, Action == R.Action, Effects == R.Effects {
        impl = { state, action, effects -> SideEffects2<Action> in
            guard var stateCopy = state else {
                return SideEffects2.none()
            }
            let sideEffects = builder().reduce(&stateCopy, action: action, effects: effects)
            state = stateCopy
            
            return sideEffects
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects2<Action> {
        impl(&state, action, effects)
    }
}
