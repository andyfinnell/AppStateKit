import Foundation

public struct ArrayReducer<State, Action>: Reducer {
    private let impl: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, [R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, Int)>,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, sideEffects -> Void in
            guard let (innerAction, index) = actionBinding.toAction(action),
                  index >= state[keyPath: keyPath].startIndex,
                  index < state[keyPath: keyPath].endIndex else {
                return
            }
            
            let innerSideEffects = sideEffects.map {
                actionBinding.fromAction(($0, index))
            }
            builder().reduce(
                &state[keyPath: keyPath][index],
                action: innerAction,
                sideEffects: innerSideEffects
            )
        }
    }
    
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        impl(&state, action, sideEffects)
    }
}
