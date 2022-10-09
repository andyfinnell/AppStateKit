import Foundation

public struct ArrayReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects2<Action>
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, [R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, Int)>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects -> SideEffects2<Action> in
            guard let (innerAction, index) = actionBinding.toAction(action),
                  index >= state[keyPath: keyPath].startIndex,
                  index < state[keyPath: keyPath].endIndex else {
                return SideEffects2.none()
            }
            
            
            let innerEffects = toEffects(effects)
            return builder().reduce(&state[keyPath: keyPath][index],
                                    action: innerAction,
                                    effects: innerEffects)
            .map({ actionBinding.fromAction(($0, index)) })
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects2<Action> {
        impl(&state, action, effects)
    }
}
