import Foundation

public struct AnonymousReducer<State, Action, Effects>: Reducer {
    private let closure: (inout State, Action, Effects) -> SideEffects<Action>
    
    public init(_ closure: @escaping (inout State, Action, Effects) -> SideEffects<Action>) {
        self.closure = closure
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action> {
        closure(&state, action, effects)
    }
}
