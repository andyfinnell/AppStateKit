import Foundation

public struct OptionalReducer<State, Action>: Reducer {
    private let impl: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init<R: Reducer>(@ReducerBuilder builder: @escaping () -> R)
    where State == R.State?, Action == R.Action {
        impl = { state, action, sideEffects -> Void in
            guard var stateCopy = state else {
                return
            }
            builder().reduce(
                &stateCopy,
                action: action,
                sideEffects: sideEffects
            )
            state = stateCopy
        }
    }
    
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        impl(&state, action, sideEffects)
    }
}
