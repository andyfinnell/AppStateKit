import Foundation

public struct ArrayReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects, SideEffects<Action>) -> Void
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, [R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, Int)>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R) {
        impl = { state, action, effects, sideEffects -> Void in
            guard let (innerAction, index) = actionBinding.toAction(action),
                  index >= state[keyPath: keyPath].startIndex,
                  index < state[keyPath: keyPath].endIndex else {
                return
            }
            
            
            let innerEffects = toEffects(effects)
            let innerSideEffects = SideEffects<R.Action>()
            builder().reduce(&state[keyPath: keyPath][index],
                                    action: innerAction,
                                    effects: innerEffects,
                                    sideEffects: innerSideEffects)
            sideEffects.appending(
                innerSideEffects,
                using: { actionBinding.fromAction(($0, index)) }
            )
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>) {
        impl(&state, action, effects, sideEffects)
    }
}
