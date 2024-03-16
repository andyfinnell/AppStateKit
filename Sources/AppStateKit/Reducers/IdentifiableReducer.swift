import Foundation

public struct IdentifiableReducer<State, Action>: Reducer {
    private let impl: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, [R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, R.State.ID)>,
                            @ReducerBuilder builder: @escaping () -> R)
    where R.State: Identifiable {
        impl = { state, action, sideEffects -> Void in
            guard let (innerAction, innerID) = actionBinding.toAction(action),
                  let index = state[keyPath: keyPath].firstIndex(where: { $0.id == innerID }),
                  index >= state[keyPath: keyPath].startIndex,
                  index < state[keyPath: keyPath].endIndex else {
                return
            }
            
            let innerSideEffects = sideEffects.map {
                actionBinding.fromAction(($0, innerID))
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
