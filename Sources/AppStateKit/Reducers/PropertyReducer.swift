import Foundation

public struct PropertyReducer<State, Action>: Reducer {
    private let impl: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, R.State>,
                            action actionBinding: ActionBinding<Action, R.Action>,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, sideEffects -> Void in
            guard let innerAction = actionBinding.toAction(action) else {
                return
            }
            let innerSideEffects = sideEffects.map(actionBinding.fromAction)
            builder().reduce(
                &state[keyPath: keyPath],
                action: innerAction,
                sideEffects: innerSideEffects
            )
        }
    }
    
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        impl(&state, action, sideEffects)
    }
}
