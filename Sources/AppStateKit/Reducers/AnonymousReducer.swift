import Foundation

public struct AnonymousReducer<State, Action, Effects>: Reducer {
    private let closure: (inout State, Action, Effects) -> SideEffects2<Action>
    
    public init(_ closure: @escaping (inout State, Action, Effects) -> SideEffects2<Action>) {
        self.closure = closure
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects2<Action> {
        closure(&state, action, effects)
    }
}
