import Foundation

public struct PropertyReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects<Action>
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, R.State>,
                            action actionBinding: ActionBinding<Action, R.Action>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects -> SideEffects<Action> in
            guard let innerAction = actionBinding.toAction(action) else {
                return SideEffects.none()
            }
            let innerEffects = toEffects(effects)
            return builder().reduce(&state[keyPath: keyPath], action: innerAction, effects: innerEffects)
                .map(actionBinding.fromAction)
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action> {
        impl(&state, action, effects)
    }
}
