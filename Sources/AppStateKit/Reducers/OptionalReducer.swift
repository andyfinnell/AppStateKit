import Foundation

public struct OptionalReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects, SideEffects<Action>) -> Void
    
    public init<R: Reducer>(@ReducerBuilder builder: @escaping () -> R)
    where State == R.State?, Action == R.Action, Effects == R.Effects {
        impl = { state, action, effects, sideEffects -> Void in
            guard var stateCopy = state else {
                return
            }
            builder().reduce(
                &stateCopy,
                action: action,
                effects: effects,
                sideEffects: sideEffects
            )
            state = stateCopy
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>) {
        impl(&state, action, effects, sideEffects)
    }
}
