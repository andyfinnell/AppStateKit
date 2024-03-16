import Foundation

public struct AnonymousReducer<State, Action, Effects>: Reducer {
    private let closure: (inout State, Action, Effects, AnySideEffects<Action>) -> Void
    
    public init(_ closure: @escaping (inout State, Action, Effects, AnySideEffects<Action>) -> Void) {
        self.closure = closure
    }
    
    public func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: AnySideEffects<Action>) {
        closure(&state, action, effects, sideEffects)
    }
}
