import Foundation

public struct EmptyReducer<State, Action, Effects>: Reducer {
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects2<Action> {
        // nop
        SideEffects2.none()
    }
}
