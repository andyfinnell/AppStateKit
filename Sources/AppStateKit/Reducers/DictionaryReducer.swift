import Foundation

public struct DictionaryReducer<State, Action>: Reducer {
    private let impl: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init<Key: Hashable, R: Reducer>(state keyPath: WritableKeyPath<State, [Key: R.State]>,
                                           action actionBinding: ActionBinding<Action, (R.Action, Key)>,
                                           @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, sideEffects -> Void in
            guard let (innerAction, innerKey) = actionBinding.toAction(action),
                  var stateCopy = state[keyPath: keyPath][innerKey] else {
                return
            }
            
            let innerSideEffects = sideEffects.map {
                actionBinding.fromAction(($0, innerKey))
            }
            builder().reduce(
                &stateCopy,
                action: innerAction,
                sideEffects: innerSideEffects
            )
            state[keyPath: keyPath][innerKey] = stateCopy
        }
    }
    
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        impl(&state, action, sideEffects)
    }
}
