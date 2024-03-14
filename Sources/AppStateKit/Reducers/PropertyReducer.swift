import Foundation

public struct PropertyReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects, SideEffects<Action>) -> Void
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, R.State>,
                            action actionBinding: ActionBinding<Action, R.Action>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects, sideEffects -> Void in
            guard let innerAction = actionBinding.toAction(action) else {
                return
            }
            let innerEffects = toEffects(effects)
            let innerSideEffects = SideEffects<R.Action>()
            builder().reduce(
                &state[keyPath: keyPath],
                action: innerAction,
                effects: innerEffects,
                sideEffects: innerSideEffects)
            
            sideEffects.appending(
                innerSideEffects,
                using: actionBinding.fromAction
            )
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>) {
        impl(&state, action, effects, sideEffects)
    }
}
