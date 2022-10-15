import Foundation

public struct DictionaryReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects<Action>
    
    public init<Key: Hashable, R: Reducer>(state keyPath: WritableKeyPath<State, [Key: R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, Key)>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects -> SideEffects<Action> in
            guard let (innerAction, innerKey) = actionBinding.toAction(action),
                  var stateCopy = state[keyPath: keyPath][innerKey] else {
                return SideEffects.none()
            }
            
            let innerEffects = toEffects(effects)
            let sideEffects = builder().reduce(&stateCopy,
                                    action: innerAction,
                                    effects: innerEffects)
                .map({ actionBinding.fromAction(($0, innerKey)) })
            
            state[keyPath: keyPath][innerKey] = stateCopy
            
            return sideEffects
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action> {
        impl(&state, action, effects)
    }
}
