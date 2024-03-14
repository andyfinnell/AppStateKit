import Foundation

public struct AnonymousReducer<State, Action, Effects>: Reducer {
    private let closure: (inout State, Action, Effects, SideEffects<Action>) -> Void
    
    public init(_ closure: @escaping (inout State, Action, Effects, SideEffects<Action>) -> Void) {
        self.closure = closure
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>) {
        closure(&state, action, effects, sideEffects)
    }
}
