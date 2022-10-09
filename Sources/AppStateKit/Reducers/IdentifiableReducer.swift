import Foundation

public struct IdentifiableReducer<State, Action, Effects>: Reducer {
    private let impl: (inout State, Action, Effects) -> SideEffects2<Action>
    
    public init<R: Reducer>(state keyPath: WritableKeyPath<State, [R.State]>,
                            action actionBinding: ActionBinding<Action, (R.Action, R.State.ID)>,
                            effects toEffects: @escaping (Effects) -> R.Effects,
                            @ReducerBuilder builder: @escaping () -> R)
    where R.State: Identifiable {
        impl = { state, action, effects -> SideEffects2<Action> in
            guard let (innerAction, innerID) = actionBinding.toAction(action),
                  let index = state[keyPath: keyPath].firstIndex(where: { $0.id == innerID }),
                  index >= state[keyPath: keyPath].startIndex,
                  index < state[keyPath: keyPath].endIndex else {
                return SideEffects2.none()
            }
            
            
            let innerEffects = toEffects(effects)
            return builder().reduce(&state[keyPath: keyPath][index],
                                    action: innerAction,
                                    effects: innerEffects)
            .map({ actionBinding.fromAction(($0, innerID)) })
        }
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects2<Action> {
        impl(&state, action, effects)
    }
}
