import Foundation

public struct DictionaryReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects, SideEffects<Action>) -> Void
    
    public init<Key: Hashable, R: Reducer>(state keyPath: WritableKeyPath<State, [Key: R.State]>,
                                           action actionBinding: ActionBinding<Action, (R.Action, Key)>,
                                           effects toEffects: @escaping (Effects) -> R.Effects,
                                           @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects, sideEffects -> Void in
            guard let (innerAction, innerKey) = actionBinding.toAction(action),
                  var stateCopy = state[keyPath: keyPath][innerKey] else {
                return
            }
            
            let innerEffects = toEffects(effects)
            let innerSideEffects = SideEffects<R.Action>()
            builder().reduce(
                &stateCopy,
                action: innerAction,
                effects: innerEffects,
                sideEffects: innerSideEffects
            )
            sideEffects.appending(
                innerSideEffects,
                using: { actionBinding.fromAction(($0, innerKey)) }
            )
            
            state[keyPath: keyPath][innerKey] = stateCopy
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>) {
        impl(&state, action, effects, sideEffects)
    }
}
